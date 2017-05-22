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
import copy

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
	
stemmer = SnowballStemmer('french')
stopw = []
for w in stopwords.words('french'):
    stopw.append(replaceAll(w))
    
path = '../data/VoeuxPresidents/'

def lecturevoeux(path):
    dico = dict()
    res = []
    names = []
    listdir = os.listdir(path)
    listdir.sort()
    for f in listdir:
        tmp = f.split('_')
        tmp2 = tmp[0].split('Dec')
        val = tmp2[-1]+' '+tmp[-1]
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
        dico[val]=alltxts
    return dico
    
def lecturevoeuxparpresident(path):
    dico = dict()
    res = []
    names = []
    listdir = os.listdir(path)
    listdir.sort()
    for f in listdir:
        tmp = f.split('_')
        val = tmp[-1]
        if val == 'OM':
            val = tmp[-2]
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
            
    return dico
    
def lecturetheme(path):
    f = codecs.open(path,'r','utf8')
    alltxts=''
    for ligne in f:
        if ligne[0] == '\n':
            continue
        tmp = ligne.split('.')
        for tmp2 in tmp:
            if tmp2 == '\n':
                break
            alltxts+=replaceAll(tmp2)
    return alltxts
    
def addtheme(textes,theme):
    text = lecturetheme(theme)
    tmp = theme.split('/')
    textes[tmp[-1]] = text
    
    return textes.keys().index(tmp[-1])
    
def cosine_sim(textes):
    vec = skfet.CountVectorizer(encoding='utf8',decode_error='strict',lowercase=True,tokenizer=tokenize,stop_words=stopw,ngram_range=(1,1),min_df=0.1,max_df=0.8,analyzer='word',dtype='int64')
    
    bow = vec.fit_transform(textes)
    
    transformer = skfet.TfidfTransformer(use_idf=True,smooth_idf=True)

    bowtf = transformer.fit_transform(bow)
    
    return (bowtf * bowtf.T).A
    
def plot_confusion_matrix(cm,names, titre):
    plt.imshow(cm, interpolation='nearest')
    plt.title(titre)
    plt.colorbar()
    tick_marks = np.arange(len(names))
    plt.xticks(tick_marks, names, rotation=90)
    plt.yticks(tick_marks, names)
    plt.tight_layout()
    plt.xlabel('Annee')
    plt.ylabel('%')
    
def plot_confusion_matrix_theme(cm,names,theme,titre,mode=0):
    if mode == 0:
        tmp = np.array([cm.tolist()])
        noms = names
        del noms[theme]
        annees = []
        for val in names:
            annees.append(int(val.split(' ')[0]))
        res = trieval(cm,annees)
        datax = []
        datay = []
        for val in res:
            datay.append(val[0])
            datax.append(val[1])
        return datax, datay
    else:
    
        dico = dict()
        dicotmp = dict()
        
        tmp = np.array([cm.tolist()])
        noms = names
        del noms[theme]
        presidents = []
        for val in names:
            presidents.append(val)
            
        res = trieval(cm,presidents,mode=2)

        datax = []
        datay = []
        for val in res:
            datay.append(val[0])
            datax.append(val[1])
        
        for cpt, val in enumerate(datax):
            tmp = val.split(' ')
            nom = tmp[1]

            if nom in dico.keys():
                dico[nom]+= datay[cpt]
                dicotmp[nom] +=1
            else:
                dico[nom] = datay[cpt]
                dicotmp[nom] = 1
        
        resy = []
        
        for cpt, val in enumerate(dico.values()):
            resy.append(val/dicotmp.values()[cpt])
        return dico.keys(), resy
        
def plot_data(path):
    
    f = open(path,'r')

    datax = []
    datay = []
    dataxbis = []
    dataybis = []
    data = []
    
    for val in f:
        tmp = val.split('\t')
        val2 = tmp[1].split('\n')
        if val2[0] != 'NR':  
            datax.append(tmp[0])
            datay.append(val2[0])
            dataxbis.append(tmp[0])
            dataybis.append(val2[0])
        else :
            dataxbis.append(tmp[0])
            dataybis.append('NaN')

    return datax, datay, dataxbis, dataybis
    
def trieval(values,annees,mode=1):

    tab = [(values[i],annees[i]) for i in range(len(annees))]
    
    if mode == 1:
        dtype = [('value',float),('annee',int)]
    else:
        dtype = [('value',float),('president','S36')]
    a = np.array(tab,dtype=dtype)
    if mode == 1:
        a = np.sort(a,order='annee')
    else :
        a = np.sort(a,order='president')
    
    return a
    
def traitement_cm_theme(cm,pos):
    tmp = cm[pos][:]
    tmp = np.delete(tmp,pos)
    ind_max = np.argmax(tmp)
    val = tmp[ind_max]
    for i, value in enumerate(tmp):
        tmp[i]=tmp[i]/val
    return tmp
    
def normalisation_valeurs(data):
    data2 = [float(val) for val in data]
    ind_max = np.argmax(data2)
    
    val = data2[ind_max]
    res = []
    for i, value in enumerate(data2):
        res.append(data2[i]/val*100)

    return res
    
def traitement_cm_theme_non_normalise(cm,pos):
    tmp = cm[pos][:]
    tmp = np.delete(tmp,pos)
    return tmp
    
def mesure_similarite(xtheme,courbetheme,xdata,courbedata):
    tab1 = []
    tab2 = []
    tab3 = []
    for cpt, val in enumerate(courbedata):
        if val != 'NaN':
            tab3.append(cpt)
    
    for cpt, val in enumerate(tab3):
        if cpt == 0:
            continue   
        if courbedata[val] > courbedata[tab3[cpt-1]]:
            tab2.append(1)
        else :
            tab2.append(0)
        if courbetheme[val] > courbetheme[tab3[cpt-1]]:
            tab1.append(1)
        else:
            tab1.append(0)

    somme = 0
    
    for cpt, val in enumerate(tab1):
        somme+=abs(val - tab2[cpt])
    
    return 100-float(somme)/float(len(tab1))*100

def algo(theme,mode=0):

    if mode == 1:
        return plot_data('../data/INSEE/'+theme)
        
    voeux = lecturevoeux(path)

    path2 = '../data/pages_wiki/'+str(theme)
    tmp = path2.split('/')

    pos = addtheme(voeux,path2)

    res = cosine_sim(voeux.values())

    np.set_printoptions(precision=1)

    cm = traitement_cm_theme_non_normalise(res,pos)
    
    return plot_confusion_matrix_theme(cm, voeux.keys(),pos,tmp[-1],mode)

    
