# نشر إجابات «خصوصية التطبيق» عبر App Store Connect API + استكشاف استبيانات الالتزام
import json, os, sys, time

import jwt, requests

KEY_ID, ISSUER = 'Y6PW89YX6J', '3aa57344-99da-4421-94f9-5aaf95c16287'
KEY = os.environ['APP_STORE_CONNECT_KEY']
API = 'https://api.appstoreconnect.apple.com'


def tok():
    now = int(time.time())
    return jwt.encode({'iss': ISSUER, 'iat': now, 'exp': now + 1100, 'aud': 'appstoreconnect-v1'}, KEY, algorithm='ES256', headers={'kid': KEY_ID})


def call(method, path, body=None):
    r = requests.request(method, API + path, headers={'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'}, data=json.dumps(body) if body else None)
    print(method, path, '→', r.status_code)
    if r.status_code >= 400:
        print(r.text[:1200])
        return None
    return r.json() if r.text else {}


APP = call('GET', '/v1/apps?filter[bundleId]=sa.almubarky.qitaat')['data'][0]['id']

print('\n===== استكشاف =====')
a = call('GET', f'/v1/apps/{APP}')
print('app relationships:', sorted((a or {}).get('data', {}).get('relationships', {}).keys()))
infos = call('GET', f'/v1/apps/{APP}/appInfos')['data']
for i in infos:
    print('appInfo', i['id'], i['attributes'].get('appStoreState'), 'relationships:', sorted(i.get('relationships', {}).keys()))

print('\n===== خصوصية التطبيق =====')
existing = call('GET', f'/v1/apps/{APP}/dataUsages?limit=200') or call('GET', f'/v1/apps/{APP}/appDataUsages?limit=200')
if existing is not None:
    print('existing usages:', len(existing.get('data', [])))
cats = ['NAME', 'PHONE_NUMBER', 'PHYSICAL_ADDRESS', 'OTHER_FINANCIAL_INFO', 'PHOTOS_OR_VIDEOS', 'EMAILS_OR_TEXT_MESSAGES', 'CUSTOMER_SUPPORT', 'USER_ID', 'PURCHASE_HISTORY']
have = set()
for u in (existing or {}).get('data', []):
    rel = u.get('relationships', {})
    have.add((rel.get('category', {}).get('data') or {}).get('id'))
for c in cats:
    if c in have:
        continue
    call('POST', '/v1/appDataUsages', {'data': {'type': 'appDataUsages', 'relationships': {
        'app': {'data': {'type': 'apps', 'id': APP}},
        'category': {'data': {'type': 'appDataUsageCategories', 'id': c}},
        'purpose': {'data': {'type': 'appDataUsagePurposes', 'id': 'APP_FUNCTIONALITY'}},
        'dataProtection': {'data': {'type': 'appDataUsageDataProtections', 'id': 'DATA_LINKED_TO_YOU'}}}}})

st = call('GET', f'/v1/apps/{APP}/dataUsagePublishState') or call('GET', f'/v1/apps/{APP}/appDataUsagesPublishState')
if st and st.get('data'):
    sid = st['data']['id']
    print('publish state', st['data'].get('attributes'))
    call('PATCH', f'/v1/appDataUsagesPublishState/{sid}', {'data': {'type': 'appDataUsagesPublishState', 'id': sid, 'attributes': {'published': True}}})
