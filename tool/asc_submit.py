# تجهيز صفحة «قطعة سيارتك» في App Store وإرسالها للمراجعة عبر App Store Connect API
# الاستخدام: python3 tool/asc_submit.py <رقم البناء> [submit]
import glob, hashlib, json, os, sys, time

import jwt, requests

KEY_ID = os.environ.get('ASC_KEY_ID', 'Y6PW89YX6J')
ISSUER = os.environ.get('ASC_ISSUER', '3aa57344-99da-4421-94f9-5aaf95c16287')
KEY = os.environ['APP_STORE_CONNECT_KEY']
BUNDLE = 'sa.almubarky.qitaat'
BUILD = sys.argv[1] if len(sys.argv) > 1 else None
SUBMIT = len(sys.argv) > 2 and sys.argv[2] == 'submit'
VERSION = '1.0.0'
API = 'https://api.appstoreconnect.apple.com'
PAGES = 'https://almubarky05588-lab.github.io/qitaat'
problems = []


def tok():
    now = int(time.time())
    return jwt.encode({'iss': ISSUER, 'iat': now, 'exp': now + 1100, 'aud': 'appstoreconnect-v1'}, KEY, algorithm='ES256', headers={'kid': KEY_ID})


def call(method, path, body=None, ok_fail=False):
    r = requests.request(method, API + path, headers={'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'}, data=json.dumps(body) if body else None)
    if r.status_code >= 400:
        msg = f'{method} {path} → {r.status_code}: {r.text[:1500]}'
        print('⚠️', msg)
        if not ok_fail:
            problems.append(msg)
        return None
    return r.json() if r.text else {}


def step(t):
    print('\n==========', t, '==========')


# ───────── النصوص ─────────
AR = {
    'name': 'قطعة سيارتك',
    'subtitle': 'سوق قطع غيار السيارات',
    'promo': 'اطلب قطعتك وتوصلك عروض الموردين المتخصصين بماركتك — قارن واختر وادفع بأمان داخل التطبيق.',
    'keywords': 'قطع غيار,قطع سيارات,تشليح,قطع اصلية,قطع مستعملة,تويوتا,هيونداي,لكزس,جي ام سي,نيسان,مورد,ورشة',
    'description': '''«قطعة سيارتك» سوق سعودي لقطع غيار السيارات يجمع المشترين بالموردين المتخصصين في مكان واحد.

اطلب قطعتك:
• اختر سيارتك (الشركة، السيارة، السنة) واكتب القطع اللي تحتاجها
• يوصل طلبك للموردين المتخصصين بماركة سيارتك فقط
• توصلك عروض بالسعر والنوع (أصلي أو تجاري) والحالة (جديد، مستعمل، مجدد) لكل قطعة
• قارن العروض واختر الأنسب وادفع داخل التطبيق

تسوّق القطع:
• تصفح إعلانات القطع حسب الماركة والتصنيف والمدينة
• رتّب النتائج بالأحدث أو الأقل سعراً أو الأعلى سعراً
• شارك في المزادات «على السوم»

للموردين والتشاليح:
• أضف إعلاناتك بالصور والسيارات المتوافقة
• استقبل طلبات العملاء المطابقة لتخصصك وقدّم عروضك
• تابع مبيعاتك وأرباحك واطلب تحويل مستحقاتك
• باقات برو وبرو ماكس: إعلانات بلا حدود وعمولة أقل وتمييز الإعلانات

أمان وثقة:
• الدفع والشراء داخل التطبيق فقط
• تصوير القطعة من 4 اتجاهات قبل الشحن
• فواتير ضريبية لكل طلب
• حماية المحادثات ومراجعة البلاغات''',
}
EN = {
    'name': 'قطعة سيارتك',
    'subtitle': 'Saudi Car Parts Marketplace',
    'promo': 'Request any car part and get offers from specialized suppliers — compare, choose and pay securely in the app.',
    'keywords': 'car parts,auto parts,spare parts,used parts,toyota,hyundai,lexus,gmc,nissan,supplier,garage,saudi',
    'description': '''Qitaat Sayartak is a Saudi marketplace for car spare parts that connects buyers with specialized suppliers.

Request a part:
• Choose your car (make, model, year) and list the parts you need
• Your request reaches suppliers specialized in your car brand
• Get offers with price, type (genuine or aftermarket) and condition for each part
• Compare offers, choose the best and pay in the app

Shop parts:
• Browse listings by brand, category and city
• Sort by newest, lowest or highest price
• Join "make an offer" auctions

For suppliers:
• Post listings with photos and compatible cars
• Receive matching customer requests and send offers
• Track sales and earnings and request payouts
• Pro plans: unlimited listings, lower commission and boosted listings

Safe and trusted:
• Buying and payment inside the app only
• Every part is photographed from 4 sides before shipping
• Tax invoice for every order''',
}
REVIEW_NOTES = '''Demo accounts (login with phone number, the verification code is 1234 for all accounts in this version):
- Buyer: phone 500000009 (country code +966 is preset), code 1234
- Supplier: phone 500000001, code 1234
The app is a marketplace for car spare parts in Saudi Arabia (Arabic UI). Buyers request parts and receive offers from suppliers; suppliers post listings. Payments use a payment gateway being activated; in this build the payment step is in test mode.'''

step('التطبيق')
apps = call('GET', f'/v1/apps?filter[bundleId]={BUNDLE}')
if not apps or not apps['data']:
    print('❌ التطبيق غير موجود'); sys.exit(1)
app = apps['data'][0]
APP = app['id']
primary = app['attributes'].get('primaryLocale')
print('app', APP, 'primaryLocale', primary, 'name', app['attributes'].get('name'))
call('PATCH', f'/v1/apps/{APP}', {'data': {'type': 'apps', 'id': APP, 'attributes': {'contentRightsDeclaration': 'DOES_NOT_USE_THIRD_PARTY_CONTENT'}}})

step('النسخة')
vers = call('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=10')['data']
for v in vers:
    print('version', v['id'], v['attributes']['versionString'], v['attributes'].get('appStoreState') or v['attributes'].get('appVersionState'))
editable = [v for v in vers if (v['attributes'].get('appVersionState') or v['attributes'].get('appStoreState')) in ('PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY')]
if editable:
    V = editable[0]['id']
    call('PATCH', f'/v1/appStoreVersions/{V}', {'data': {'type': 'appStoreVersions', 'id': V, 'attributes': {'versionString': VERSION, 'copyright': '2026 قطعة سيارتك', 'releaseType': 'AFTER_APPROVAL'}}})
else:
    r = call('POST', '/v1/appStoreVersions', {'data': {'type': 'appStoreVersions', 'attributes': {'platform': 'IOS', 'versionString': VERSION, 'copyright': '2026 قطعة سيارتك', 'releaseType': 'AFTER_APPROVAL'}, 'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})
    if not r:
        print('❌ ما قدرت أنشئ نسخة'); sys.exit(1)
    V = r['data']['id']
print('VERSION_ID', V)

step('معلومات التطبيق (الاسم، الخصوصية، التصنيف، الفئة العمرية)')
infos = call('GET', f'/v1/apps/{APP}/appInfos')['data']
info = next((i for i in infos if i['attributes'].get('appStoreState') != 'READY_FOR_SALE'), infos[0])
INFO = info['id']
call('PATCH', f'/v1/appInfos/{INFO}', {'data': {'type': 'appInfos', 'id': INFO, 'relationships': {
    'primaryCategory': {'data': {'type': 'appCategories', 'id': 'SHOPPING'}},
    'secondaryCategory': {'data': {'type': 'appCategories', 'id': 'BUSINESS'}}}}})
locs = {l['attributes']['locale']: l['id'] for l in call('GET', f'/v1/appInfos/{INFO}/appInfoLocalizations')['data']}
print('appInfo locales', locs)


def info_loc(locale, t):
    attrs = {'name': t['name'], 'subtitle': t['subtitle'], 'privacyPolicyUrl': f'{PAGES}/privacy/'}
    if locale in locs:
        call('PATCH', f'/v1/appInfoLocalizations/{locs[locale]}', {'data': {'type': 'appInfoLocalizations', 'id': locs[locale], 'attributes': attrs}})
    else:
        call('POST', '/v1/appInfoLocalizations', {'data': {'type': 'appInfoLocalizations', 'attributes': {'locale': locale, **attrs}, 'relationships': {'appInfo': {'data': {'type': 'appInfos', 'id': INFO}}}}})


info_loc('ar-SA', AR)
if primary and primary != 'ar-SA':
    info_loc(primary, EN if primary.startswith('en') else AR)

age = call('GET', f'/v1/appInfos/{INFO}/ageRatingDeclaration')
if age:
    AGE = age['data']['id']
    cur = age['data']['attributes']
    skip = {'kidsAgeBand', 'ageRatingOverride', 'koreaAgeRatingOverride', 'ageRatingOverrideV2', 'developerAgeRatingInfoUrl', 'gracRatingClassificationNumber'}
    enums = {'alcoholTobaccoOrDrugUseOrReferences', 'contests', 'gamblingSimulated', 'gunsOrOtherWeapons', 'horrorOrFearThemes', 'matureOrSuggestiveThemes',
             'medicalOrTreatmentInformation', 'profanityOrCrudeHumor', 'sexualContentGraphicAndNudity', 'sexualContentOrNudity', 'violenceCartoonOrFantasy',
             'violenceRealistic', 'violenceRealisticProlongedGraphicOrSadistic'}
    yes = {'messagingAndChat', 'userGeneratedContent'}  # محادثات بين المستخدمين وإعلانات يضيفونها
    want = {k: ('NONE' if k in enums else (k in yes)) for k in cur if k not in skip}
    import re as _re
    for attempt in range(8):
        r = requests.patch(API + f'/v1/ageRatingDeclarations/{AGE}', headers={'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'},
                           data=json.dumps({'data': {'type': 'ageRatingDeclarations', 'id': AGE, 'attributes': want}}))
        if r.status_code < 400:
            print('✅ age rating saved')
            break
        bad = _re.findall(r"attribute '(\w+)'\. Expected a (\w+)", r.text)
        unknown = _re.findall(r'"pointer" : "/data/attributes/(\w+)"', r.text)
        print('age retry', attempt, bad or r.text[:400])
        if not bad and not unknown:
            problems.append('age rating: ' + r.text[:600]); break
        for k, t in bad:
            want[k] = (k in yes) if t == 'BOOLEAN' else 'NONE'
        if not bad:
            for k in unknown:
                want.pop(k, None)
    else:
        problems.append('age rating لم يُحفظ')

step('وصف النسخة والروابط')
vlocs = {l['attributes']['locale']: l['id'] for l in call('GET', f'/v1/appStoreVersions/{V}/appStoreVersionLocalizations')['data']}
print('version locales', vlocs)


def ver_loc(locale, t):
    attrs = {'description': t['description'], 'keywords': t['keywords'], 'promotionalText': t['promo'], 'supportUrl': f'{PAGES}/support/', 'marketingUrl': f'{PAGES}/support/'}
    if locale in vlocs:
        call('PATCH', f'/v1/appStoreVersionLocalizations/{vlocs[locale]}', {'data': {'type': 'appStoreVersionLocalizations', 'id': vlocs[locale], 'attributes': attrs}})
        return vlocs[locale]
    r = call('POST', '/v1/appStoreVersionLocalizations', {'data': {'type': 'appStoreVersionLocalizations', 'attributes': {'locale': locale, **attrs}, 'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': V}}}}})
    return r['data']['id'] if r else None


loc_ids = {'ar-SA': ver_loc('ar-SA', AR)}
if primary and primary != 'ar-SA':
    loc_ids[primary] = ver_loc(primary, EN if primary.startswith('en') else AR)

step('صور الشاشات')
shots = sorted(glob.glob(os.path.join(os.path.dirname(__file__), 'shots', 'final', '*.png')))
print('screenshots', len(shots))
for locale, LID in loc_ids.items():
    if not LID or not shots:
        continue
    sets = call('GET', f'/v1/appStoreVersionLocalizations/{LID}/appScreenshotSets')['data']
    sset = next((s for s in sets if s['attributes']['screenshotDisplayType'] == 'APP_IPHONE_67'), None)
    if sset:
        for old in call('GET', f'/v1/appScreenshotSets/{sset["id"]}/appScreenshots')['data']:
            call('DELETE', f'/v1/appScreenshots/{old["id"]}', ok_fail=True)
        SID = sset['id']
    else:
        SID = call('POST', '/v1/appScreenshotSets', {'data': {'type': 'appScreenshotSets', 'attributes': {'screenshotDisplayType': 'APP_IPHONE_67'}, 'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': LID}}}}})['data']['id']
    for f in shots:
        data = open(f, 'rb').read()
        r = call('POST', '/v1/appScreenshots', {'data': {'type': 'appScreenshots', 'attributes': {'fileName': os.path.basename(f), 'fileSize': len(data)}, 'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': SID}}}}})
        if not r:
            continue
        sid = r['data']['id']
        for op in r['data']['attributes']['uploadOperations']:
            part = data[op['offset']:op['offset'] + op['length']]
            requests.request(op['method'], op['url'], headers={h['name']: h['value'] for h in op['requestHeaders']}, data=part)
        call('PATCH', f'/v1/appScreenshots/{sid}', {'data': {'type': 'appScreenshots', 'id': sid, 'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}})
        print('uploaded', locale, os.path.basename(f))

step('بيانات المراجعة')
rd = call('GET', f'/v1/appStoreVersions/{V}/appStoreReviewDetail', ok_fail=True)
review = {'contactFirstName': 'Nabil', 'contactLastName': 'Almubarky', 'contactPhone': '+966559796917', 'contactEmail': 'almubarky05588@gmail.com',
          'demoAccountName': '500000009', 'demoAccountPassword': '1234', 'demoAccountRequired': True, 'notes': REVIEW_NOTES}
if rd and rd.get('data'):
    call('PATCH', f'/v1/appStoreReviewDetails/{rd["data"]["id"]}', {'data': {'type': 'appStoreReviewDetails', 'id': rd['data']['id'], 'attributes': review}})
else:
    call('POST', '/v1/appStoreReviewDetails', {'data': {'type': 'appStoreReviewDetails', 'attributes': review, 'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': V}}}}})

step('السعر: مجاني')
pts = call('GET', f'/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=200', ok_fail=True)
free = next((p for p in (pts or {}).get('data', []) if float(p['attributes']['customerPrice']) == 0), None)
if free:
    call('POST', '/v1/appPriceSchedules', {
        'data': {'type': 'appPriceSchedules', 'relationships': {
            'app': {'data': {'type': 'apps', 'id': APP}},
            'baseTerritory': {'data': {'type': 'territories', 'id': 'USA'}},
            'manualPrices': {'data': [{'type': 'appPrices', 'id': '${price1}'}]}}},
        'included': [{'type': 'appPrices', 'id': '${price1}', 'attributes': {'startDate': None},
                      'relationships': {'appPricePoint': {'data': {'type': 'appPricePoints', 'id': free['id']}}}}]}, ok_fail=True)

step('التوفر في الدول')
av = call('GET', f'/v1/apps/{APP}/appAvailabilityV2', ok_fail=True)
if not av:
    terr = [t['id'] for t in call('GET', '/v1/territories?limit=200')['data']]
    call('POST', '/v2/appAvailabilities', {
        'data': {'type': 'appAvailabilities', 'attributes': {'availableInNewTerritories': True}, 'relationships': {
            'app': {'data': {'type': 'apps', 'id': APP}},
            'territoryAvailabilities': {'data': [{'type': 'territoryAvailabilities', 'id': f'${{t{i}}}'} for i, _ in enumerate(terr)]}}},
        'included': [{'type': 'territoryAvailabilities', 'id': f'${{t{i}}}', 'attributes': {'available': True},
                      'relationships': {'territory': {'data': {'type': 'territories', 'id': t}}}} for i, t in enumerate(terr)]}, ok_fail=True)
else:
    print('availability already set')

step(f'البناء {BUILD}')
if BUILD:
    b = None
    for _ in range(40):
        bs = call('GET', f'/v1/builds?filter[app]={APP}&filter[version]={BUILD}&limit=1')
        b = bs['data'][0] if bs and bs['data'] else None
        st = b['attributes']['processingState'] if b else 'NOT_FOUND'
        print('build', BUILD, st)
        if st == 'VALID':
            break
        time.sleep(30)
    if b and b['attributes']['processingState'] == 'VALID':
        if b['attributes'].get('usesNonExemptEncryption') is None:
            call('PATCH', f'/v1/builds/{b["id"]}', {'data': {'type': 'builds', 'id': b['id'], 'attributes': {'usesNonExemptEncryption': False}}}, ok_fail=True)
        call('PATCH', f'/v1/appStoreVersions/{V}/relationships/build', {'data': {'type': 'builds', 'id': b['id']}})
    else:
        problems.append(f'البناء {BUILD} غير جاهز')

if SUBMIT:
    step('الإرسال للمراجعة')
    subs = call('GET', f'/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES', ok_fail=True)
    open_sub = (subs or {}).get('data') or []
    if open_sub:
        SUB = open_sub[0]['id']
        print('existing submission', SUB, open_sub[0]['attributes']['state'])
    else:
        r = call('POST', '/v1/reviewSubmissions', {'data': {'type': 'reviewSubmissions', 'attributes': {'platform': 'IOS'}, 'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})
        SUB = r['data']['id'] if r else None
    if SUB:
        call('POST', '/v1/reviewSubmissionItems', {'data': {'type': 'reviewSubmissionItems', 'relationships': {
            'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': SUB}},
            'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': V}}}}}, ok_fail=True)
        r = call('PATCH', f'/v1/reviewSubmissions/{SUB}', {'data': {'type': 'reviewSubmissions', 'id': SUB, 'attributes': {'submitted': True}}})
        if r:
            print('✅ SUBMITTED', r['data']['attributes'].get('state'))

step('النتيجة')
if problems:
    print('PROBLEMS:')
    for p in problems:
        print(' -', p)
else:
    print('✅ كل شي تمام')
