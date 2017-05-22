#!/usr/bin/python
# -*-coding:Utf-8 -*

import scipy
import numpy as  np
import codecs
import sklearn.naive_bayes as nb
import sklearn.feature_extraction.text as skfet
import sklearn.decomposition as skdec
from sklearn import svm
from sklearn import linear_model as lin
import re
from nltk import word_tokenize
from nltk.stem import SnowballStemmer
import nltk.corpus.reader as pt
import cPickle as pickle
import unicodedata
import string
from collections import Counter,defaultdict
import os
import io
import codecs

def tokenize(text):
	stemmer = SnowballStemmer('french')
	tokens = word_tokenize(text)
	stems = [ stemmer.stem (item) for item in tokens ]
	return stems

def replacemult(string,old,new):
	nstring = string

	for i in range(len(old)):
		nstring = nstring.replace(old[i],new[i])

	return nstring

def replaceAll(string):
	return replacemult(string,[u'é',u'è',u'ê',u'à',u'â',u'î',u'ï',u'ô',u'û',u'ù',u"'",u'-',u'ç',u'œ'],['e','e','e','a','a','i','i','o','u','u',' ',' ','c','oe'])

def replaceAllList(lstr):
	l = lstr[:]
	for i,string in enumerate(lstr):
		l[i] = replaceAll(string)
	return l
	

def lecture(filename):
	alltxts=[]
	f = codecs.open(filename, 'r','latin1')
	cpt = 0
	for ligne in f:
		tmp = replaceAll(ligne).split('>')
		alltxts.append(tmp[1])
		cpt+=1
		if cpt < 100 or cpt > 300000:
			print tmp[1]
	f.close()
	return alltxts
 
filename = u'../data/DEFT/corpus_discours.learn'

path2data = '../data/VoeuxPresidents/'

rdr = pt.CategorizedPlaintextCorpusReader(path2data, '.*/[0-9]+', encoding='utf-8', cat_pattern='([\w\.]+)/*')
docs = [rdr.raw(fileids=[f]) for f in os.listdir(path2data)]

alltxts = (np.asarray(lecture(filename))).reshape(-1,1)



#vec = skdec.LatentDirichletAllocation(learning_method='batch')

vec = skfet.CountVectorizer(encoding='utf-8',decode_error='strict',strip_accents='ascii',lowercase=False,tokenizer=None,stop_words=None,ngram_range=(1,1),analyzer='word',
max_df=0.5,min_df=0.05,dtype='int64')

#bow = vec.fit_transform(alltxts)

bowTest = vec.transform(docs)

transformer = skfet.TfidfTransformer(use_idf=True,smooth_idf=True)

bowtf = transformer.fit_transform(bow)
bowtf = ''


test = open('./test.txt','wb')
pickle.dump({'bow' : bowtf,'dico' : vec.vocabulary_},test)
test.close()

#bowtfTest = transformer.transform(bowTest)
