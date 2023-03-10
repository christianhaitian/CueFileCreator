#!/usr/bin/python3

import glob, os, sys
import re
from os import walk

ROMS_PATH = sys.argv[1]

def static():
	pass

def writeTrack(aCueFilename, aFilename, aTrackNumber):

	myOutputText = ""
	myFilenameWithoutPath = os.path.basename(aFilename)

	if aTrackNumber == 1 and "/pcfx/" not in aFilename and aTrackNumber == 1 and "/pcenginecd/" not in aFilename and aTrackNumber == 1 and "/turbografxcd/" not in aFilename:
		myOutputText = "FILE \"{filename}\" BINARY\nTRACK {track:02d} MODE1/2352\nINDEX {track:02d} 00:00:00"\
		 .format(filename = myFilenameWithoutPath, track = aTrackNumber)
	elif aTrackNumber == 2 and "/pcfx/" in aFilename or aTrackNumber == 2 and "/pcenginecd/" in aFilename or aTrackNumber == 2 and "/turbografxcd/" in aFilename:
		myOutputText = "\nFILE \"{filename}\" BINARY\nTRACK {track:02d} MODE1/2352\nINDEX 00 00:00:00\nINDEX 01 00:03:00\n"\
		 .format(filename = myFilenameWithoutPath, track = aTrackNumber)
	else:
		if "/segacd/" or "/neogeocd/" or "/pcfx/" or "/pcenginecd/" or "/turbografxcd/" in aFilename:
		   myOutputText = "\nFILE \"{filename}\" BINARY\nTRACK {track:02d} AUDIO\nINDEX 00 00:00:00\nINDEX 01 00:02:00"\
			.format(filename = myFilenameWithoutPath, track = aTrackNumber)
		else:
		   myOutputText = "\nTRACK \"{filename}\" BINARY\nTRACK {track:02d} AUDIO\nINDEX 00 00:00:00\nINDEX 01 00:02:00"\
			.format(filename = myFilenameWithoutPath, track = aTrackNumber)

	try:
		myFile = open(aCueFilename, "a")
		myFile.write(myOutputText)
	except IOError:
		print("Error trying to access file: {0}\n".format(aCueFilename))
	finally:
		myFile.close()

def getCueFileName(aFilename):

	if static.regularExpressions == None:
		static.regularExpressions = \
		[re.compile(r"\((\.|\s)*track(.+?)(\d)+", flags=re.I)] 

	for myRegularExpression in static.regularExpressions:

		reFind = myRegularExpression.search(aFilename)

		if reFind != None:

			myFindWord = reFind.group()

			myIndex = aFilename.find(myFindWord)

			if(myIndex > 0):

				return (aFilename[0:myIndex]).rstrip()

	indexLastPoint = aFilename.rfind(".")

	return aFilename[:indexLastPoint].rstrip()

def existsCueFileName(aFilename):

	myFullPath = os.path.join(ROMS_PATH, aFilename)

	if os.path.isfile(myFullPath):
		return True
	else:
		return False

def getAllBinFiles():

	myCounter = 0
	myTrackNumber = 1
	myCueFilenameFormat = "{0}.cue"
	mySearchFilePath = os.path.join(ROMS_PATH, "*.bin")
	myCueFilename = None

	myFileList = sorted(glob.glob(mySearchFilePath))

	myFileListSize = len(myFileList);

	for myFileName in myFileList:

		myCounter = myCounter + 1

		myTempCueFilename = getCueFileName(myFileName)

		if myCueFilename == None or myCueFilename != myTempCueFilename:

			myTrackNumber = 1

			if existsCueFileName(myCueFilenameFormat.format(myTempCueFilename)) == False:

				myCueFilename = myTempCueFilename

			else:

				continue


		if myCueFilename != None:

			writeTrack(myCueFilenameFormat.format(myCueFilename), myFileName, myTrackNumber)

			myTrackNumber = myTrackNumber + 1
			with open('/dev/shm/CueFileCreator.log', 'a') as f:
			    print (myCueFilename + ".cue", file=f)

def getAllBinSubFiles():

  for (dirpath, dirnames, filenames) in walk(ROMS_PATH):
	  for dir in dirnames:
	    myCounter = 0
	    myTrackNumber = 1
	    myCueFilenameFormat = "{0}.cue"
	    mySearchFilePath = os.path.join(ROMS_PATH + dir, "*.bin")
	    myCueFilename = None

	    myFileList = sorted(glob.glob(mySearchFilePath))

	    myFileListSize = len(myFileList);

	    for myFileName in myFileList:

		    myCounter = myCounter + 1

		    myTempCueFilename = getCueFileName(myFileName)

		    if myCueFilename == None or myCueFilename != myTempCueFilename:

			    myTrackNumber = 1

			    if existsCueFileName(myCueFilenameFormat.format(myTempCueFilename)) == False:

				    myCueFilename = myTempCueFilename

			    else:

				    continue


		    if myCueFilename != None:

			    writeTrack(myCueFilenameFormat.format(myCueFilename), myFileName, myTrackNumber)
			    myTrackNumber = myTrackNumber + 1
			    with open('/dev/shm/CueFileCreator.log', 'a') as f:
			        print (myCueFilename + ".cue", file=f)

static.regularExpressions = None

getAllBinFiles()
getAllBinSubFiles()
