#!/usr/bin/env python

import requests
import json

FILE_NAME_DEF = 'hr_file_to_upload.json'

API_URL = 'https://api.figshare.com/v2/institution/hrfeed/upload'
KEY_FILE = '../conf/figshare_hr_key.json'

with open(KEY_FILE) as json_file:
    json_data = json.load(json_file)

TOKEN=json_data['hr_figshare_token']

with open(FILE_NAME_DEF) as json_file:
    json_data = json.load(json_file)

FILE_NAME=json_data['filename']

def main():
    headers = {"Authorization": "token " + TOKEN}
    with open(FILE_NAME, 'rb') as fin:
        files = {'hrfeed': (FILE_NAME, fin)}
        resp = requests.post(API_URL, files=files, headers=headers)

        print(resp.content)

        resp.raise_for_status()

if __name__ == '__main__':
    main()
