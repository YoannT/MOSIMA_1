#!/usr/bin/python
# -*- coding: utf-8 -*-

import numpy as  np
import codecs
import matplotlib.pyplot as plt
import unicodedata
import re
from collections import Counter,defaultdict
import os
import string
import pdb
import nltk
import scipy
import numpy.random as rand
import nltk.corpus.reader as pt
import cPickle as pickle

def gen_dico(corpus):
    dico = None
    new_corps = []
    for doc in corpus:
        sentences = preprocessSent(doc)
        sentences = [s[:-1] for s in sentences if len(s)>2]
        new_corps.append(sentences)
        for s in sentences:
            dico = count_ngrams(s.split(),n=1, dic=dico)
    
    dicoTmp = dico.copy()
    
    for mot in dicoTmp:
        if dico[mot] < 5:
            del dico[mot]
    
    return dico, new_corps

def preprocessSent(s):
    punc = u''.join([ch for ch in string.punctuation if ch != '.']) # je laisse les points pour pouvoir séparer les phrases
    punc += u'\n\r\t\\'
    table =string.maketrans(punc + string.digits, ' '*(len(punc)+len(string.digits)))
    s = string.translate(unicodedata.normalize("NFKD",s).encode("ascii","ignore"),table).lower() # elimination des accents + minuscules
    return re.sub(" +"," ",re.sub("\.+","\.",s)).split() # renvoie des phrases dans une liste

def count_ngrams(s,n=2,dic=None):
    if dic is None:
        dic=Counter()
    for i in range(len(s)):
        for j in range(i+1,min(i+n+1,len(s)+1)):
            dic[u''.join(s[i:j])]+=1
    return dic


data = pickle.load(open('./test.txt','r'))

bowtf = data['bow']
dico = data['dico']
res = 0

X = bowtf

max = 0
argmax = 0
vals = []
thmDoc = []
    
res = dict((v,k) for k,v in dico.iteritems())

for pos, doc in enumerate(bowtf) :
    max = 0
    argmax = 0
    if bowtf[pos].nnz == 0:
        print 'TEST'
        continue
    for cpt, val in enumerate(bowtf[pos].todok().items()):
        if val[1] > max:
            max = val[1]
            argmax = cpt
    '''        
    print "pos ",pos             
    print argmax
    print bowtf[pos]
    print bowtf[pos].todok().keys()[argmax][1]'''
    thmDoc.append(res[bowtf[pos].todok().keys()[argmax][1]])
    
test1, test2 = gen_dico(thmDoc)

print test1
'''            
for cpt, val in enumerate(bowtf[0].todok().items()):
    if val[1] == max:
        max = val[1]
        vals.append(cpt)

print vals

for val in vals:
    print res[bowtf[0].todok().keys()[val][1]]
'''

print 'fin'
