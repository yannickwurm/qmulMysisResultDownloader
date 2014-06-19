qmulMysisResultDownloader
=========================

To use this: 

 * create/edit config.rb as per the example


Current shortcomings: 

 * doesn't exclude debtors  (would need to add a filter for this at line 52). 
 * only does year 1 + 2
 * filtering of study programs is VERY approximate - around line 52. WILL NOT WORK WITH ALL DEGREES.
 * supposes that the MySis site won't change. 
 * tested only with ruby 2.1.1p76 on my mac. 
 * only tested from gmail
 