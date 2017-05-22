#!/usr/bin/python
# -*-coding:Utf-8 -*

import os
import codecs

path = './data/VoeuxPresidents/'

def replacemult(string,old,new):
	nstring = string

	for i in range(len(old)):
		nstring = nstring.replace(old[i],new[i])

	return nstring

def replaceAll(string):
	return replacemult(string,[u'é',u'è',u'ê',u'à',u'â',u'î',u'ï',u'ô',u'û',u'ù',u"'",u'-',u'ç',u'œ'],['e','e','e','a','a','i','i','o','u','u',' ',' ','c','oe'])

def lecturevoeux(path):
	res = []
	names = []
	listdir = os.listdir(path)
	listdir.sort()
	for f in listdir:
		names.append(f)
		alltxts=''
		fic = codecs.open(path+f,'r','utf8')
		for ligne in fic:
			if ligne[0] == '\n':
				continue
			tmp = ligne.split('.')
			for tmp2 in tmp:
				if tmp2 == '\n':
					break
				alltxts+=replaceAll(tmp2)
		res.append(alltxts)
	return res, names

def lectureTitres(path):
  names = []
  listdir = os.listdir(path)
  listdir.sort()
  for f in listdir:
	names.append(f)
	f = open("res","w")
	
	for n in names:
		f.write("-"+n+"\n")
	f.close()

lectureTitres(path)
