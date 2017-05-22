#!/usr/bin/python
# -*-coding:Utf-8 -*

import BeautifulSoup
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

def tokenize(text):
    stemmer = SnowballStemmer('french')
    tokens = word_tokenize(text)
    stems = [ stemmer.stem (item) for item in tokens ]
    return stems

def lectureFichierXML(filename):
    alltxts=[]
    f = io.open(filename, 'r',encoding='utf8')
    data= f.read()
    soup = BeautifulSoup.BeautifulSoup(data)
    contents = soup.findAll('texte') # recherche de la nouvelle balise
    for content in contents:
        alltxts.append(content.text)
    return alltxts
 
filename = u'../data/DEFT/deft09_parlement_appr_fr.xml'

path2data = '../data/VoeuxPresidents/'

rdr = pt.CategorizedPlaintextCorpusReader(path2data, '.*/[0-9]+', encoding='latin1', cat_pattern='([\w\.]+)/*')
docs = [rdr.raw(fileids=[f]) for f in os.listdir(path2data)]

alltxts = (np.asarray(lectureFichierXML(filename))).reshape(-1,1)

print alltxts[0]

if (alltxts[0] < 0).any():
    print 'caca'

#vec = skdec.LatentDirichletAllocation(learning_method='batch')

'''
vec = skfet.CountVectorizer(encoding='utf-8',decode_error='strict',strip_accents='ascii',lowercase=False,tokenizer=None,stop_words=None,ngram_range=(1,1),analyzer='word',
max_df=0.5,min_df=0.05,dtype='int64')'''

#bow = vec.fit_transform(alltxts)

'''
bowTest = vec.transform(docs)

transformer = skfet.TfidfTransformer(use_idf=True,smooth_idf=True)

bowtf = transformer.fit_transform(bow)'''
bowtf = ''


test = open('./test.txt','wb')
pickle.dump({'bow' : bowtf,'dico' : vec.vocabulary_},test)
test.close()

#bowtfTest = transformer.transform(bowTest)

print 'fin'
