import requests
import urllib.request
import re
from bs4 import BeautifulSoup
import os

a_url = 'https://hpaudiobooks.club/harry-potter-order-of-phoenix-audiobook-hp-5/'
a_list = [2,3,4,5,6,7,8,9,10]
for x in range(1,11):
    url = '{}/{}/'.format(a_url,x)

    r = requests.get(url, verify=False)
    soup = BeautifulSoup(r.content, 'html.parser')


    for a in soup.find_all('a', href=re.compile(r'http.*\.mp3')):
        filename = a['href'][a['href'].rfind("/")+1:]
        pathname = 'C:/Users/robevans/Downloads/'
        fullpath = os.path.join(pathname,filename)
        doc = requests.get(a['href'],verify=False)
        with open(fullpath, 'wb') as f:
            f.write(doc.content)