#!/usr/bin/python
# -*-coding:Utf-8 -*

import urllib2
from bs4 import BeautifulSoup
import codecs

urls = ['https://fr.wikipedia.org/wiki/Environnement']

def replacemult(string,old,new):
	nstring = string

	for i in range(len(old)):
		nstring = nstring.replace(old[i],new[i])

	return nstring

def replaceAll(string):
	return replacemult(string,[u'é',u'è',u'ê',u'à',u'â',u'î',u'ï',u'ô',u'û',u'ù',u"'",u'-',u'ç',u'œ'],['e','e','e','a','a','i','i','o','u','u',' ',' ','c','oe'])

def writePages(urls):
	global path
	for the_url in urls:
		req = urllib2.Request(the_url)
		handle = urllib2.urlopen(req)
		the_page = handle.read()

		soup = BeautifulSoup(the_page, 'html.parser')

		text = replaceAll(soup.getText())

		newTxt = text.split(u"Un article de Wikipedia, l encyclopedie libre.")[1].split(u"\nNotes et references")[0]

		name = the_url.decode('utf8').split('/')
		name = name[len(name)-1]

		f = codecs.open(path+name, "w", "utf-8")
		f.write(newTxt)
		f.close()

path = '../data/pages_wiki/'

writePages(urls)
