#!/usr/bin/python
# -*-coding:Utf-8 -*

import os
import codecs

def reverse(path):
	names = []
	listdir = os.listdir(path)
	for f in listdir:
		if '_copie' not in f:
			print f
			names.append(f)
			fic = codecs.open(path+f,'r','utf8')
			lines = fic.readlines()	
			newfic =  codecs.open(path+f+'_copie','w','utf8')
			print lines,len(lines)
			for i in range(len(lines)-1,-1,-1):
				newfic.write(lines[i])
				print lines[i]
			fic.close()
			newfic.close()


	return names

path = "./"

reverse(path)
