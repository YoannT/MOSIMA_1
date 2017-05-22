#!/usr/bin/python
# -*-coding:Utf-8 -*

from Tkinter import *
import Tkinter as Tk
import matplotlib.pyplot as plt
import algotest
import os
import numpy
import csv
import codecs


def affichagematriceconfusion():

	tab = []
	tabnoms = []
	anneeselections = [1980,1987,1994,2001,2006,2011]
	
	for cpt, val in enumerate(tabVar):
		if tabVar[cpt].get() == 1:
			datax, datay = algotest.algo(tabVal[cpt])
			tab.append(datay)
			tabnoms.append(tabVal[cpt])
	
	tabannees = []
	for val in datax:
		if val in anneeselections:
			if val == 1980:
				tmp = str(val)+' (VGE)'
			elif val == 1987 or val == 1994:
				tmp = str(val)+' (FM)'
			elif val == 2001 or val == 2006:
				tmp = str(val)+' (JC)'
			elif val == 2011:
				tmp = str(val)+' (NS)'
			tabannees.append(tmp+'*')
		else:
			if val < 1981:
				tmp = str(val)+' (VGE)'
			elif val >= 1981 and val < 1994:
				tmp = str(val)+' (FM)'
			elif val >= 1994 and val < 2007:
				tmp = str(val)+' (JC)'
			elif val >= 2007 and val < 2012:
				tmp = str(val)+' (NS)'
			else:
				tmp = str(val)+' (FH)'
			tabannees.append(tmp)
			
	plt.imshow(tab, interpolation='nearest')
	plt.title('Matrice de confusion')
	plt.colorbar()
	tick_marks = numpy.arange(len(tabannees))
	tick_marks_y = numpy.arange(len(tabnoms))
	plt.xticks(tick_marks, tabannees, rotation=90)
	plt.yticks(tick_marks_y, tabnoms)
	plt.tight_layout()
	plt.xlabel('Annees')
	plt.ylabel('Themes')
	plt.show()
	return

def lireEval(fic,pathThemes):

	f = codecs.open(fic,'r','utf8')
	lines = f.readlines()
	f.close()

	themes = []

	dico = dict()
	listdir = os.listdir(pathThemes)
	listdir.sort()
	for f in listdir:
		themes.append(f)


	tabannees = []
	for l in lines:
		if '-' in l:
			tabannees.append(l.split('_')[0].strip('-'))

	m = [[0 for j in range(len(tabannees))] for i in range(len(themes))]

	cpt = -1

	for l in lines:
		if '-' in l:
			cpt += 1
		else:
			indTheme = themes.index(l.split(' ')[0])
			m[indTheme][cpt] = int(l.split(' ')[1])

	print m

	plt.imshow(m, interpolation='nearest')
	plt.title('Matrice de confusion')
	plt.colorbar()
	tick_marks = numpy.arange(len(tabannees))
	tick_marks_y = numpy.arange(len(themes))
	plt.xticks(tick_marks, tabannees, rotation=90)
	plt.yticks(tick_marks_y, themes)
	plt.tight_layout()
	plt.xlabel('Annees')
	plt.ylabel('Themes')
	plt.show()
	return

lireEval('res','./data/pages_wiki')

