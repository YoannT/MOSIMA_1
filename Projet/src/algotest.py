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
    
def lecturevoeuxparpresident(path):
    dico = dict()
    res = []
    names = []
    listdir = os.listdir(path)
    listdir.sort()
    for f in listdir:
        tmp = f.split('_')
        val = tmp[len(tmp)-1]
        if val == 'OM':
            val = tmp[len(tmp)-2]
            
        print val
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
                
        if val in dico.keys():
            dico[val]+= alltxts
        else:
            dico[val] = alltxts
    return dico.values(), dico.keys()
    
def cosine_sim(textes):
    vec = skfet.CountVectorizer(encoding='utf8',decode_error='strict',lowercase=True,tokenizer=None,stop_words=stopw,ngram_range=(1,1),min_df=1,max_df=1.0,analyzer='word',dtype='int64')
    
    bow = vec.fit_transform(textes)
    
    transformer = skfet.TfidfTransformer(use_idf=True,smooth_idf=True)

    bowtf = transformer.fit_transform(bow)
    
    return (bowtf * bowtf.T).A
    
def plot_confusion_matrix(cm,names, title='Matrice de confusion'):
    plt.imshow(cm, interpolation='nearest')
    plt.title(title)
    plt.colorbar()
    tick_marks = np.arange(len(names))
    plt.xticks(tick_marks, names, rotation=45)
    plt.yticks(tick_marks, names)
    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label')
    
stemmer = SnowballStemmer('french')
stopw = []
for w in stopwords.words('french'):
    stopw.append(replaceAll(w))
    
path = '../data/VoeuxPresidents/'

voeux, names = lecturevoeuxparpresident(path)

res = cosine_sim(voeux)

cm = res

np.set_printoptions(precision=2)
print('Confusion matrix, without normalization')
plt.figure()
plot_confusion_matrix(cm, names)

'''
# Normalize the confusion matrix by row (i.e by the number of samples
# in each class)
cm_normalized = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
print('Normalized confusion matrix')
plt.figure()
plot_confusion_matrix(cm_normalized,names,title='Normalized confusion matrix')'''

plt.show()

