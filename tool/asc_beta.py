# TestFlight خارجي: مجموعة مختبرين خارجية + رابط عام + إرسال البناء لمراجعة بيتا
# الاستخدام: python3 tool/asc_beta.py <رقم البناء>   (إعادة التشغيل تعرض الحالة والرابط فقط)
import json, os, sys, time

import jwt, requests

KEY_ID = os.environ.get('ASC_KEY_ID', 'Y6PW89YX6J')
ISSUER = os.environ.get('ASC_ISSUER', '3aa57344-99da-4421-94f9-5aaf95c16287')
KEY = os.environ['APP_STORE_CONNECT_KEY']
BUNDLE = 'sa.almubarky.qitaat'
BUILD = sys.argv[1]
GROUP = 'Public Testers'
API = 'https://api.appstoreconnect.apple.com'
EMAIL = 'almubarky05588@gmail.com'


def tok():
    now = int(time.time())
    return jwt.encode({'iss': ISSUER, 'iat': now, 'exp': now + 1100, 'aud': 'appstoreconnect-v1'}, KEY, algorithm='ES256', headers={'kid': KEY_ID})


def call(method, path, body=None):
    r = requests.request(method, API + path, headers={'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'}, data=json.dumps(body) if body else None)
    if r.status_code >= 400:
        print(f'⚠️ {method} {path} → {r.status_code}: {r.text[:1200]}')
        return None
    return r.json() if r.text else {}


app = call('GET', f'/v1/apps?filter[bundleId]={BUNDLE}')['data'][0]
APP = app['id']
print('app', APP)

# البناء (ننتظر انتهاء المعالجة)
for _ in range(40):
    b = call('GET', f'/v1/builds?filter[app]={APP}&filter[version]={BUILD}&limit=1')
    if b and b['data'] and b['data'][0]['attributes']['processingState'] == 'VALID':
        break
    print('بانتظار معالجة البناء...'); time.sleep(30)
build = b['data'][0]
BID = build['id']
print('build', BUILD, BID, build['attributes']['processingState'])
call('PATCH', f'/v1/builds/{BID}', {'data': {'type': 'builds', 'id': BID, 'attributes': {'usesNonExemptEncryption': False}}})

# وصف النسخة التجريبية
desc = 'Qitaat Sayartak is a Saudi marketplace for car spare parts: buyers request parts and get offers from specialized suppliers, or buy listed parts directly and pay inside the app.'
locs = call('GET', f'/v1/apps/{APP}/betaAppLocalizations')['data']
en = next((l for l in locs if l['attributes']['locale'] == 'en-US'), None)
attrs = {'description': desc, 'feedbackEmail': EMAIL, 'privacyPolicyUrl': 'https://almubarky05588-lab.github.io/qitaat/privacy/', 'marketingUrl': 'https://almubarky05588-lab.github.io/qitaat/support/'}
if en:
    call('PATCH', f"/v1/betaAppLocalizations/{en['id']}", {'data': {'type': 'betaAppLocalizations', 'id': en['id'], 'attributes': attrs}})
else:
    call('POST', '/v1/betaAppLocalizations', {'data': {'type': 'betaAppLocalizations', 'attributes': {**attrs, 'locale': 'en-US'}, 'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})

# بيانات مراجعة بيتا (حساب تجريبي)
notes = ('Login with phone number (country code +966 is preset). Demo accounts, verification code is 1234:\n'
         '- Buyer: 500000009\n- Supplier: 500000001\nThe app UI is in Arabic.')
call('PATCH', f'/v1/betaAppReviewDetails/{APP}', {'data': {'type': 'betaAppReviewDetails', 'id': APP, 'attributes': {
    'contactFirstName': 'Nabil', 'contactLastName': 'Almubarky', 'contactPhone': '+966559796917', 'contactEmail': EMAIL,
    'demoAccountRequired': True, 'demoAccountName': '500000009', 'demoAccountPassword': '1234', 'notes': notes}}})

# ما الجديد في هذا البناء
bl = call('GET', f'/v1/builds/{BID}/betaBuildLocalizations')['data']
wn = {'whatsNew': 'Full marketplace flow: part requests, supplier offers, listings, cart and checkout.'}
if bl:
    call('PATCH', f"/v1/betaBuildLocalizations/{bl[0]['id']}", {'data': {'type': 'betaBuildLocalizations', 'id': bl[0]['id'], 'attributes': wn}})
else:
    call('POST', '/v1/betaBuildLocalizations', {'data': {'type': 'betaBuildLocalizations', 'attributes': {**wn, 'locale': 'en-US'}, 'relationships': {'build': {'data': {'type': 'builds', 'id': BID}}}}})

# المجموعة الخارجية برابط عام
groups = call('GET', f'/v1/apps/{APP}/betaGroups?limit=50')['data']
g = next((x for x in groups if x['attributes']['name'] == GROUP), None)
if not g:
    g = call('POST', '/v1/betaGroups', {'data': {'type': 'betaGroups', 'attributes': {'name': GROUP, 'publicLinkEnabled': True, 'publicLinkLimitEnabled': False, 'feedbackEnabled': True},
                                                 'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})['data']
GID = g['id']
call('POST', f'/v1/betaGroups/{GID}/relationships/builds', {'data': [{'type': 'builds', 'id': BID}]})

# الإرسال لمراجعة بيتا
st = call('GET', f'/v1/builds/{BID}/betaAppReviewSubmission')
if not (st and st.get('data')):
    call('POST', '/v1/betaAppReviewSubmissions', {'data': {'type': 'betaAppReviewSubmissions', 'relationships': {'build': {'data': {'type': 'builds', 'id': BID}}}}})
    st = call('GET', f'/v1/builds/{BID}/betaAppReviewSubmission')
print('\nحالة مراجعة بيتا:', (st or {}).get('data', {}).get('attributes', {}).get('betaReviewState'))

g = call('GET', f'/v1/betaGroups/{GID}')['data']['attributes']
if not g.get('publicLinkEnabled'):
    call('PATCH', f'/v1/betaGroups/{GID}', {'data': {'type': 'betaGroups', 'id': GID, 'attributes': {'publicLinkEnabled': True, 'publicLinkLimitEnabled': False}}})
    g = call('GET', f'/v1/betaGroups/{GID}')['data']['attributes']
print('الرابط العام:', g.get('publicLink'))
