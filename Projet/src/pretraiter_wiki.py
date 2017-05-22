#!/usr/bin/python
# -*-coding:Utf-8 -*

import os
import codecs
import sklearn.feature_extraction.text as skfet
import sklearn.decomposition as skdec
from nltk import word_tokenize
from nltk.stem import SnowballStemmer
import matplotlib.pyplot as plt
import numpy as np
from nltk.corpus import stopwords

def tokenize(text):
	tokens = word_tokenize(text)
	stems = [stemmer.stem(item) for item in tokens]
	return stems

def replacemult(string,old,new):
	nstring = string

	for i in range(len(old)):
		nstring = nstring.replace(old[i],new[i])

	return nstring

def replaceAll(string):
	return replacemult(string,[u'é',u'è',u'ê',u'à',u'â',u'î',u'ï',u'ô',u'û',u'ù',u"'",u'-',u'ç',u'œ'],['e','e','e','a','a','i','i','o','u','u',' ',' ','c','oe'])

def lecturewiki(path):
	res = []
	names = []
	listdir = os.listdir(path)
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
	
def cosine_sim(textes):
	global stopw
	vec = skfet.CountVectorizer(encoding='utf8',decode_error='strict',lowercase=True,tokenizer=None,stop_words=stopw,ngram_range=(1,1),min_df=0.0,max_df=1.0,analyzer='word',dtype='int64')
	
	bow = vec.fit_transform(textes)
	
	transformer = skfet.TfidfTransformer(use_idf=True,smooth_idf=True)

	bowtf = transformer.fit_transform(bow)
	
	return bowtf

def lire_freq(textes):
	dico = dict()
	for t in textes:
		for mot in t.split():
			mot = mot.split('[')[0].strip('(),:\n')
			if not mot in dico.keys():
				dico[mot]=1
			else:
				dico[mot]+=1
	return dico


stemmer = SnowballStemmer('french')
stopw = []
for w in stopwords.words('french'):
	stopw.append(replaceAll(w))
	
path = '../data/pages_wiki/'

voeux, names = lecturewiki(path)

#res = cosine_sim(voeux)
res = lire_freq(voeux)
print res

4978740363908170
