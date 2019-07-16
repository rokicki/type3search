#!/usr/bin/python
# coding: utf-8
#
#   Fetched from https://apple.stackexchange.com/questions/155250/trying-to-convert-pdf-to-text-for-free/229009
#   from answer by `benwiggy'.
#

import os, sys
from Quartz import PDFDocument
from CoreFoundation import (NSURL, NSString)
NSUTF8StringEncoding = 4

def pdf2txt():
    for filename in sys.argv[1:]:   
        inputfile =filename.decode('utf-8')
        shortName = os.path.splitext(filename)[0]
        outputfile = shortName+".txt"
        pdfURL = NSURL.fileURLWithPath_(inputfile)
        pdfDoc = PDFDocument.alloc().initWithURL_(pdfURL)
        if pdfDoc :
            pdfString = NSString.stringWithString_(pdfDoc.string())
            pdfString.writeToFile_atomically_encoding_error_(outputfile, True, NSUTF8StringEncoding, None)

if __name__ == "__main__":
   pdf2txt()
