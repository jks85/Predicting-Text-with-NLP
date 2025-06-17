# Predicting-Text-with-NLP
Texting prediction in R using NLP (Natural Language Processing)

### Description
This repo contains the code used to create an interactive text prediction app. The app predicts the final word using the previous 3 words. The prediction model implemented Simple Backoff using Maximum Likelihood Estimation. The app validates input by correcting spelling and filtering obscenities.

### Accuracy
The app was trained on small data set of words, ~30k lines and as such does not perform particularly well. The model performed with ~10.8% accuracy against the validation set, but has not yet been tested against the test set. In addition to the small training data set, the low accuracy is not surprising given use of Simple Backoff. Methods for improving model accuracy include application of smoothing techniques (e.g. Kneser-Ney Smoothing) and/or using continuation probabilities. These methods would likely improve model accuracy by further incorporating the likelihood that words appear together.

However, in creating this model and app it is clear that n-grams do not offer a viable method for large scale text prediction.


### Files

The files ui.R and server.R provide the frontend and backend code, respectively for the app

File names of the form *___gram_5_table_short.csv* contain n-grams of a particular token length (e.g. bi_gram refers to pairs of tokens). The file name includes "short" as the original database of n-grams was too large for R Shiny to support

