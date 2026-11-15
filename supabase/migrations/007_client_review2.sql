-- الجولة الثانية من ملاحظات العميل (تقرير لولو) — 007

-- ───────── إعدادات جديدة ─────────
insert into public.app_settings (key, value, label) values
  ('payout_business_days', '7', 'أيام العمل قبل إتاحة مستحقات المورد (من تاريخ الشحن)'),
  ('payout_holidays', '[]', 'إجازات رسمية لا تُحسب من أيام العمل (قائمة تواريخ YYYY-MM-DD)'),
  ('cr_edit_hours', '24', 'مهلة تعديل السجل التجاري بالساعات من أول حفظ')
on conflict (key) do nothing;

-- ───────── تجاوز الحماية من داخل الدوال الموثوقة فقط ─────────
create or replace function public.protect_profile()
returns trigger language plpgsql as $$
begin
  if auth.uid() is not null and not public.is_admin() and coalesce(current_setting('app.trusted', true), '') <> 'on' then
    new.role := old.role; new.verified := old.verified; new.plan := old.plan; new.phone := old.phone;
    new.is_admin := old.is_admin; new.admin_role := old.admin_role; new.banned := old.banned; new.banned_reason := old.banned_reason;
    if new.verify_status is distinct from old.verify_status and new.verify_status <> 'pending' then new.verify_status := old.verify_status; end if;
    new.verify_note := old.verify_note;
    new.deleted_at := old.deleted_at;
    new.cr_set_at := old.cr_set_at;
    -- السجل التجاري: يُعدَّل خلال المهلة من أول حفظ فقط، وبعدها عن طريق الدعم
    if new.store_cr is distinct from old.store_cr then
      if coalesce(old.store_cr, '') = '' then
        new.cr_set_at := now();
      elsif old.cr_set_at is null or old.cr_set_at < now() - make_interval(hours => public.setting_num('cr_edit_hours', 24)::int) then
        raise exception 'انتهت مهلة تعديل السجل التجاري — اطلب التعديل من الدعم الفني';
      end if;
    end if;
  elsif coalesce(old.store_cr, '') = '' and coalesce(new.store_cr, '') <> '' and new.cr_set_at is null then
    new.cr_set_at := now();
  end if;
  return new;
end $$;

alter table public.profiles add column if not exists cr_set_at timestamptz;
alter table public.profiles add column if not exists deleted_at timestamptz;
alter table public.profiles add column if not exists store_lat double precision;
alter table public.profiles add column if not exists store_lng double precision;
-- السجلات الحالية: نعطيها مهلة 24 ساعة من الآن
update public.profiles set cr_set_at = now() where coalesce(store_cr, '') <> '' and cr_set_at is null;

-- ───────── تذاكر الدعم (طلب تعديل السجل وغيره) ─────────
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null default 'general',
  subject text not null,
  body text,
  status text not null default 'open' check (status in ('open', 'in_progress', 'done', 'rejected')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.support_tickets enable row level security;
drop policy if exists tickets_own_read on public.support_tickets;
create policy tickets_own_read on public.support_tickets for select using (user_id = auth.uid());
drop policy if exists tickets_own_insert on public.support_tickets;
create policy tickets_own_insert on public.support_tickets for insert with check (user_id = auth.uid());
drop policy if exists admin_all_tickets on public.support_tickets;
create policy admin_all_tickets on public.support_tickets for all using (public.is_admin()) with check (public.is_admin());

create or replace function public.on_ticket_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  if new.status is distinct from old.status then
    perform public.notify(new.user_id, 'support', 'تحديث على طلبك: ' || new.subject,
      case new.status when 'done' then 'تم تنفيذ طلبك' when 'rejected' then 'تم رفض الطلب' when 'in_progress' then 'طلبك قيد المعالجة' else 'طلبك مفتوح' end
      || coalesce(' — ' || new.admin_note, ''), '/support');
  end if;
  return new;
end $$;
drop trigger if exists ticket_update on public.support_tickets;
create trigger ticket_update before update on public.support_tickets for each row execute function public.on_ticket_update();

-- ───────── بلاغات المحادثات (رصد البيع والتحويل خارج التطبيق) ─────────
create table if not exists public.chat_reports (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid references public.profiles(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'violation', 'dismissed')),
  admin_note text,
  created_at timestamptz not null default now()
);
alter table public.chat_reports enable row level security;
drop policy if exists reports_own on public.chat_reports;
create policy reports_own on public.chat_reports for select using (reporter_id = auth.uid());
drop policy if exists reports_insert on public.chat_reports;
create policy reports_insert on public.chat_reports for insert with check (
  reporter_id = auth.uid() and exists (select 1 from public.conversations c where c.id = conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())));
drop policy if exists admin_all_reports on public.chat_reports;
create policy admin_all_reports on public.chat_reports for all using (public.is_admin()) with check (public.is_admin());
alter table public.profiles add column if not exists violations int not null default 0;

create or replace function public.on_report()
returns trigger language plpgsql security definer set search_path = public as $$
declare c public.conversations;
begin
  if tg_op = 'INSERT' then
    select * into c from public.conversations where id = new.conversation_id;
    new.reported_id := case when new.reporter_id = c.buyer_id then c.seller_id else c.buyer_id end;
    insert into public.notifications (user_id, kind, title, body, link)
    select id, 'admin', 'بلاغ محادثة جديد', new.reason, null from public.profiles where is_admin;
  elsif new.status = 'violation' and old.status <> 'violation' and new.reported_id is not null then
    update public.profiles set violations = violations + 1 where id = new.reported_id;
    perform public.notify(new.reported_id, 'admin', 'تنبيه مخالفة',
      'رصدنا محاولة إتمام بيع أو تحويل خارج التطبيق. تكرار المخالفة يعرّض الحساب للإيقاف.', null);
  end if;
  return new;
end $$;
drop trigger if exists report_ins on public.chat_reports;
create trigger report_ins before insert or update on public.chat_reports for each row execute function public.on_report();

-- ───────── التسوية: العمولة على المورد وإتاحة المستحقات بعد 7 أيام عمل من الشحن ─────────
alter table public.orders add column if not exists commission_rate numeric;
alter table public.orders add column if not exists commission numeric;
alter table public.orders add column if not exists seller_net numeric;
alter table public.orders add column if not exists available_at timestamptz;
alter table public.orders add column if not exists payout_status text not null default 'held';
alter table public.orders add column if not exists payout_id uuid;
alter table public.orders add column if not exists items jsonb;

create or replace function public.add_business_days(p_from timestamptz, p_days int)
returns timestamptz language plpgsql stable security definer set search_path = public as $$
declare d date := (p_from at time zone 'Asia/Riyadh')::date; c int := 0;
        hol jsonb := coalesce((select value from public.app_settings where key = 'payout_holidays'), '[]'::jsonb);
begin
  while c < p_days loop
    d := d + 1;
    -- الجمعة (5) والسبت (6) والإجازات الرسمية لا تُحسب
    if extract(isodow from d) not in (5, 6) and not (hol ? to_char(d, 'YYYY-MM-DD')) then c := c + 1; end if;
  end loop;
  return (d + (p_from at time zone 'Asia/Riyadh')::time) at time zone 'Asia/Riyadh';
end $$;

create or replace function public.order_settlement()
returns trigger language plpgsql security definer set search_path = public as $$
declare pl text;
begin
  -- نسبة العمولة تُثبَّت وقت الدفع حسب باقة المورد ولا تتغير بعدها
  if new.paid_at is not null and new.commission_rate is null then
    select plan into pl from public.profiles where id = new.seller_id;
    new.commission_rate := public.plan_commission(pl);
  end if;
  if new.commission_rate is not null then
    new.commission := round(new.subtotal * new.commission_rate / 100, 2);
    new.seller_net := new.subtotal + new.shipping - new.commission;
  end if;
  if new.shipped_at is not null and (new.available_at is null or new.shipped_at is distinct from old.shipped_at) then
    new.available_at := public.add_business_days(new.shipped_at, public.setting_num('payout_business_days', 7)::int);
  end if;
  if new.status = 'cancelled' and new.payout_status = 'held' then new.payout_status := 'cancelled'; end if;
  return new;
end $$;
drop trigger if exists order_settlement on public.orders;
create trigger order_settlement before update on public.orders for each row execute function public.order_settlement();

-- الطلبات الحالية
update public.orders o set commission_rate = public.plan_commission(p.plan) from public.profiles p
 where p.id = o.seller_id and o.paid_at is not null and o.commission_rate is null;
update public.orders set payout_status = 'cancelled' where status = 'cancelled' and payout_status = 'held';

-- طلبات التحويل
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  amount numeric not null,
  holder text, bank text, iban text,
  status text not null default 'requested' check (status in ('requested', 'processing', 'paid', 'rejected')),
  ref text, admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz
);
alter table public.payouts enable row level security;
drop policy if exists payouts_own on public.payouts;
create policy payouts_own on public.payouts for select using (user_id = auth.uid());
drop policy if exists admin_all_payouts on public.payouts;
create policy admin_all_payouts on public.payouts for all using (public.is_admin()) with check (public.is_admin());

create or replace function public.request_payout()
returns uuid language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); acc public.payout_accounts; amt numeric; pid uuid;
begin
  select * into acc from public.payout_accounts where user_id = me;
  if acc.iban is null then raise exception 'أضف حسابك البنكي أولاً من تعديل الملف'; end if;
  select coalesce(sum(seller_net), 0) into amt from public.orders
   where seller_id = me and payout_status = 'held' and status in ('shipped', 'delivered') and available_at <= now();
  if amt <= 0 then raise exception 'ما فيه رصيد متاح للتحويل حالياً'; end if;
  insert into public.payouts (user_id, amount, holder, bank, iban) values (me, amt, acc.holder_name, acc.bank_name, acc.iban) returning id into pid;
  update public.orders set payout_status = 'requested', payout_id = pid
   where seller_id = me and payout_status = 'held' and status in ('shipped', 'delivered') and available_at <= now();
  insert into public.notifications (user_id, kind, title, body, link)
  select id, 'admin', 'طلب تحويل مستحقات', (select coalesce(name, 'مورد') from public.profiles where id = me) || ' طلب تحويل ' || amt || ' ر.س', null from public.profiles where is_admin;
  return pid;
end $$;

create or replace function public.on_payout_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  if new.status is distinct from old.status then
    if new.status = 'paid' then
      new.paid_at := coalesce(new.paid_at, now());
      update public.orders set payout_status = 'paid' where payout_id = new.id;
      perform public.notify(new.user_id, 'payout', 'تم تحويل مستحقاتك', 'حوّلنا ' || new.amount || ' ر.س لحسابك البنكي' || coalesce(' — مرجع ' || new.ref, ''), '/m/earnings');
    elsif new.status = 'processing' then
      update public.orders set payout_status = 'processing' where payout_id = new.id;
      perform public.notify(new.user_id, 'payout', 'طلب التحويل قيد التنفيذ', 'جاري تحويل ' || new.amount || ' ر.س لحسابك', '/m/earnings');
    elsif new.status = 'rejected' then
      update public.orders set payout_status = 'held', payout_id = null where payout_id = new.id;
      perform public.notify(new.user_id, 'payout', 'تعذّر التحويل', coalesce(new.admin_note, 'راجع بيانات حسابك البنكي وأعد الطلب'), '/m/earnings');
    end if;
  end if;
  return new;
end $$;
drop trigger if exists payout_update on public.payouts;
create trigger payout_update before update on public.payouts for each row execute function public.on_payout_update();

create or replace function public.merchant_stats(p_days integer default 7)
returns json language sql security definer set search_path = public as $$
  select json_build_object(
    'earnings', coalesce((select sum(subtotal) from public.orders where seller_id = auth.uid() and status in ('paid','preparing','shipped','delivered') and paid_at > now() - (p_days || ' days')::interval), 0),
    'available', coalesce((select sum(seller_net) from public.orders where seller_id = auth.uid() and payout_status = 'held' and status in ('shipped','delivered') and available_at <= now()), 0),
    'pending', coalesce((select sum(seller_net) from public.orders where seller_id = auth.uid() and payout_status = 'held' and status in ('paid','preparing','shipped','delivered') and (available_at is null or available_at > now())), 0),
    'next_available_at', (select min(available_at) from public.orders where seller_id = auth.uid() and payout_status = 'held' and status in ('shipped','delivered') and available_at > now()),
    'in_transfer', coalesce((select sum(seller_net) from public.orders where seller_id = auth.uid() and payout_status in ('requested','processing')), 0),
    'paid_out', coalesce((select sum(seller_net) from public.orders where seller_id = auth.uid() and payout_status = 'paid'), 0),
    'commission_total', coalesce((select sum(commission) from public.orders where seller_id = auth.uid() and paid_at is not null and status <> 'cancelled'), 0),
    'new_requests', (select count(*) from public.notifications where user_id = auth.uid() and kind = 'request' and created_at > now() - (p_days || ' days')::interval),
    'offers_sent', (select count(*) from public.offers where supplier_id = auth.uid()),
    'offers_accepted', (select count(*) from public.offers where supplier_id = auth.uid() and status = 'accepted'),
    'views', coalesce((select sum(views) from public.listings where seller_id = auth.uid()), 0),
    'active', (select count(*) from public.listings where seller_id = auth.uid() and status = 'active'),
    'low_stock', (select count(*) from public.listings where seller_id = auth.uid() and status = 'active' and quantity <= 1),
    'sold', (select count(*) from public.listings where seller_id = auth.uid() and status = 'sold'),
    'daily', (select coalesce(json_agg(coalesce(t.s, 0) order by d), '[]'::json) from generate_series(current_date - 6, current_date, '1 day') d
              left join (select paid_at::date dd, sum(subtotal) s from public.orders where seller_id = auth.uid() and paid_at is not null group by 1) t on t.dd = d)
  );
$$;

create or replace function public.confirm_received(p_order uuid)
returns void language plpgsql security definer set search_path = public as $$
declare o public.orders;
begin
  select * into o from public.orders where id = p_order;
  if o.buyer_id <> auth.uid() then raise exception 'غير مسموح'; end if;
  if o.status <> 'shipped' then raise exception 'الطلب لم يُشحن بعد'; end if;
  update public.orders set status = 'delivered', delivered_at = now() where id = o.id;
  perform public.notify(o.seller_id, 'order', 'تم تسليم الطلب', 'أكّد المشتري استلام ' || o.order_no || ' — مستحقاتك تُتاح بعد ' || public.setting_num('payout_business_days', 7)::int || ' أيام عمل من تاريخ الشحن', '/m/earnings');
end $$;

-- العمولة في إحصائيات الإدارة من المبلغ المسجَّل وقت الشراء
create or replace function public.admin_stats(p_days integer default 30)
returns json language plpgsql stable security definer set search_path = public as $$
declare r json;
begin
  if not public.is_admin() then raise exception 'غير مسموح'; end if;
  select json_build_object(
    'users', (select count(*) from profiles),
    'buyers', (select count(*) from profiles where role = 'buyer'),
    'merchants', (select count(*) from profiles where role = 'merchant'),
    'verified', (select count(*) from profiles where role = 'merchant' and verified),
    'pending_verify', (select count(*) from profiles where verify_status = 'pending'),
    'banned', (select count(*) from profiles where banned),
    'new_users', (select count(*) from profiles where created_at > now() - make_interval(days => p_days)),
    'listings', (select count(*) from listings where status = 'active'),
    'auctions', (select count(*) from listings where status = 'active' and sale_type = 'auction'),
    'requests_open', (select count(*) from part_requests where status = 'open' and expires_at > now()),
    'requests', (select count(*) from part_requests where created_at > now() - make_interval(days => p_days)),
    'offers', (select count(*) from offers where created_at > now() - make_interval(days => p_days)),
    'orders', (select count(*) from orders where created_at > now() - make_interval(days => p_days)),
    'orders_open', (select count(*) from orders where status in ('paid','preparing','shipped')),
    'awaiting_payment', (select count(*) from orders where status = 'awaiting_payment'),
    'gmv', (select coalesce(sum(total),0) from orders where paid_at > now() - make_interval(days => p_days) and status <> 'cancelled'),
    'commission', (select coalesce(round(sum(coalesce(o.commission, o.subtotal * public.plan_commission(s.plan) / 100)), 2),0) from orders o join profiles s on s.id = o.seller_id where o.paid_at > now() - make_interval(days => p_days) and o.status <> 'cancelled'),
    'payouts_pending', (select count(*) from payouts where status in ('requested','processing')),
    'tickets_open', (select count(*) from support_tickets where status in ('open','in_progress')),
    'reports_open', (select count(*) from chat_reports where status = 'open'),
    'masked_messages', (select count(*) from messages where masked and created_at > now() - make_interval(days => p_days)),
    'daily', (select json_agg(json_build_object('d', d::date, 'gmv', coalesce(g.s,0), 'orders', coalesce(g.c,0), 'users', coalesce(u.c,0)) order by d)
              from generate_series(current_date - (p_days - 1), current_date, '1 day') d
              left join (select paid_at::date dd, sum(total) s, count(*) c from orders where paid_at is not null and status <> 'cancelled' group by 1) g on g.dd = d
              left join (select created_at::date dd, count(*) c from profiles group by 1) u on u.dd = d)
  ) into r;
  return r;
end $$;

-- ───────── حذف الحساب مع حفظ حقوق العملاء ─────────
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  if exists (select 1 from public.orders where (seller_id = me or buyer_id = me) and status in ('paid','preparing','shipped')) then
    raise exception 'عندك طلبات جارية (مدفوعة أو قيد الشحن) — أكملها قبل حذف الحساب';
  end if;
  if exists (select 1 from public.orders where seller_id = me and paid_at is not null and status <> 'cancelled' and payout_status in ('held','requested','processing')) then
    raise exception 'عندك مستحقات لم تُحوَّل بعد — انتظر تحويلها ثم احذف الحساب';
  end if;
  perform set_config('app.trusted', 'on', true);
  update public.listings set status = 'paused' where seller_id = me and status in ('active','draft');
  update public.part_requests set status = 'closed' where buyer_id = me and status = 'open';
  update public.offers set status = 'withdrawn' where supplier_id = me and status = 'pending';
  update public.orders set status = 'cancelled' where (buyer_id = me or seller_id = me) and status = 'awaiting_payment';
  delete from public.cart_items where user_id = me;
  delete from public.favorites where user_id = me;
  update public.profiles set deleted_at = now(), banned = true, banned_reason = 'حُذف الحساب بطلب المستخدم', receive_requests = false where id = me;
end $$;

-- ───────── عرض السعر لكل قطعة (توفر جزئي) ─────────
alter table public.offers add column if not exists items jsonb;

create or replace function public.offer_items()
returns trigger language plpgsql as $$
declare t numeric := 0; e jsonb; n int := 0;
begin
  if new.items is not null and jsonb_typeof(new.items) = 'array' and jsonb_array_length(new.items) > 0 then
    for e in select * from jsonb_array_elements(new.items) loop
      if coalesce((e->>'available')::boolean, true) then
        if coalesce((e->>'unit_price')::numeric, 0) <= 0 then raise exception 'اكتب سعر القطعة «%» أو علّمها غير متوفرة', e->>'name'; end if;
        t := t + (e->>'unit_price')::numeric * greatest(coalesce((e->>'qty')::int, 1), 1);
        n := n + 1;
      end if;
    end loop;
    if n = 0 then raise exception 'لازم تكون قطعة وحدة على الأقل متوفرة'; end if;
    new.price := t;
  end if;
  return new;
end $$;
drop trigger if exists offer_a0_items on public.offers;
create trigger offer_a0_items before insert or update of items on public.offers for each row execute function public.offer_items();

create or replace function public.accept_offer(p_offer uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare o public.offers; r public.part_requests; oid uuid; parts text;
begin
  select * into o from public.offers where id = p_offer;
  select * into r from public.part_requests where id = o.request_id;
  if r.buyer_id <> auth.uid() then raise exception 'غير مسموح'; end if;
  if o.status <> 'pending' then raise exception 'العرض غير متاح'; end if;
  parts := coalesce((select string_agg(e->>'name', '، ') from jsonb_array_elements(coalesce(o.items, '[]'::jsonb)) e where coalesce((e->>'available')::boolean, true)),
                    array_to_string(r.parts, '، '));
  update public.offers set status = 'accepted' where id = o.id;
  update public.offers set status = 'rejected' where request_id = r.id and id <> o.id and status = 'pending';
  update public.part_requests set status = 'closed' where id = r.id;
  insert into public.orders (buyer_id, seller_id, offer_id, title, condition, subtotal, shipping, items)
  values (r.buyer_id, o.supplier_id, o.id, parts || ' ' || r.brand || coalesce(' ' || r.model, '') || coalesce(' ' || r.year, ''), o.condition, o.price,
          case when o.includes_shipping then 0 else 35 end, o.items)
  returning id into oid;
  perform public.notify(o.supplier_id, 'accepted', 'تم قبول عرضك', 'قبل العميل عرضك على ' || parts || ' — بانتظار الدفع', '/m/sales');
  return oid;
end $$;

-- ───────── أكثر من سيارة متوافقة للقطعة ─────────
alter table public.listings add column if not exists fitments jsonb not null default '[]'::jsonb;
alter table public.listings add column if not exists fit_brands text[] not null default '{}';
alter table public.listings add column if not exists featured_from timestamptz;

create or replace function public.listing_fitments()
returns trigger language plpgsql as $$
declare f jsonb;
begin
  if jsonb_typeof(new.fitments) = 'array' and jsonb_array_length(new.fitments) > 0 then
    f := new.fitments->0;
    new.brand := coalesce(f->>'brand', new.brand);
    new.model := nullif(f->>'model', '');
    new.year_from := nullif(f->>'from', '')::int;
    new.year_to := nullif(f->>'to', '')::int;
    new.fit_brands := array(select distinct e->>'brand' from jsonb_array_elements(new.fitments) e where coalesce(e->>'brand', '') <> '');
  else
    new.fit_brands := case when coalesce(new.brand, '') = '' then '{}' else array[new.brand] end;
  end if;
  return new;
end $$;
drop trigger if exists listing_fitments on public.listings;
create trigger listing_fitments before insert or update of fitments, brand on public.listings for each row execute function public.listing_fitments();

update public.listings set fitments = jsonb_build_array(jsonb_strip_nulls(jsonb_build_object('brand', brand, 'model', model, 'from', year_from, 'to', year_to)))
 where coalesce(brand, '') <> '' and fitments = '[]'::jsonb;
create index if not exists listings_fit_brands on public.listings using gin (fit_brands);

-- ───────── مزايا الباقات: جدولة التمييز، قوالب العروض، تنبيه المخزون ─────────
create or replace function public.boost_listing(p_listing uuid, p_start timestamptz default null)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare l listings; q json; st timestamptz := greatest(coalesce(p_start, now()), now()); until_ts timestamptz;
begin
  select * into l from listings where id = p_listing;
  if l.seller_id <> auth.uid() then raise exception 'غير مسموح'; end if;
  if l.status <> 'active' then raise exception 'التمييز للإعلانات النشطة فقط'; end if;
  if l.featured_until is not null and l.featured_until > now() then raise exception 'الإعلان مميز أو مجدول تمييزه حالياً'; end if;
  if st > now() + interval '7 days' then raise exception 'تقدر تجدول التمييز خلال 7 أيام فقط'; end if;
  q := public.boost_quota();
  if (q->>'quota')::int = 0 then raise exception 'تمييز الإعلانات متاح في باقة برو وبرو ماكس'; end if;
  if (q->>'left')::int <= 0 then raise exception 'استخدمت كل رصيد التمييز في باقتك'; end if;
  until_ts := st + make_interval(hours => (q->>'hours')::int);
  update listings set featured_from = case when st > now() then st else null end, featured_until = until_ts where id = p_listing;
  insert into listing_boosts (user_id, listing_id) values (auth.uid(), p_listing);
  return until_ts;
end $$;

create table if not exists public.offer_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.offer_templates enable row level security;
drop policy if exists templates_own on public.offer_templates;
create policy templates_own on public.offer_templates for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.low_stock_alert()
returns trigger language plpgsql security definer set search_path = public as $$
declare pl text;
begin
  if new.status = 'active' and new.quantity <= 1 and old.quantity > 1 then
    select plan into pl from profiles where id = new.seller_id;
    if pl in ('pro', 'pro_max') then
      perform public.notify(new.seller_id, 'stock', 'المخزون قارب ينفد', '«' || new.title || '» باقي منه ' || new.quantity || ' — حدّث الكمية', '/m/listings');
    end if;
  end if;
  return new;
end $$;
drop trigger if exists low_stock on public.listings;
create trigger low_stock after update of quantity on public.listings for each row execute function public.low_stock_alert();
