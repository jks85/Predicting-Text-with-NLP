library(shiny)
library(quanteda)
library(data.table)
library(hunspell)

# Define server logic required to create ngram model and predict text
# from user input
function(input, output, session) {

    
    #setwd("C:/Users/jksim/Desktop/Capstone/Predicting-Text-with-NLP")
  
    # read in data tables for lookup
    # uni_dt5 <- fread("C:/Users/jksim/Desktop/Capstone/Predicting-Text-with-NLP/unigram_5_table_short.csv")
    # bi_dt5 <- fread("C:/Users/jksim/Desktop/Capstone/Predicting-Text-with-NLP/bigram_5_table_short.csv")
    # tri_dt5 <- fread("C:/Users/jksim/Desktop/Capstone/Predicting-Text-with-NLP/trigram_5_table_short.csv")
    # quad_dt5 <- fread("C:/Users/jksim/Desktop/Capstone/Predicting-Text-with-NLP/quadgram_5_table_short.csv")
    # obscenities_dt <- fread("obscenities_table.csv", fill = TRUE)
    
    # read in data tables for lookup
    uni_dt5 <- fread("./unigram_5_table_short.csv")
    bi_dt5 <- fread("./bigram_5_table_short.csv")
    tri_dt5 <- fread("./trigram_5_table_short.csv")
    quad_dt5 <- fread("./quadgram_5_table_short.csv")
    obscenities_dt <- fread("./obscenities_table.csv", fill = TRUE)
  
    # function that gets misspelled words and replacements
    find_misspellings <- function(text){
      
      if(length(hunspell(text))==0){
        
        possible_misspellings <- data.table(misspellings = c("N/A"), replacements = "N/A")
        
      }
      
      else{
        # get list of misspellings
        misspelled <- sapply(text, hunspell)[[1]]
        misspelled_low <- tolower(misspelled)
        
        # suggested corrections
        corrections_list <- sapply(misspelled_low,hunspell_suggest)
        
        # replacements
        repl <- sapply(corrections_list,function(x){x[[1]]})
        
        possible_misspellings <- data.table(misspellings = misspelled_low, replacements = repl)
        
      }
    }
    
    # prediction function
    # code is folded
    predict_back_off <- function(text, predictions = 1){
      
      # contains helpers to check for obscenities
      # may add helper to check spelling
      # contains four prediction functions to predict unigram, bigram, trigram, and quadgram
      
      ## HELPER FUNCTIONS
      
      ## check if word is an obscenity
      is_obscenity <- function(word){
        
        return(word %in% obscenities_dt[,obscenities])
        
        # if(word %in% obscenities_dt[,obscenities]){
        #     return(TRUE)
        #   }
        # else{
        #   return(FALSE)
        # }
        # 
      }
      
      ## replace obscenities
      repl_obsc <- function(words){
        
        # words is a character vector to be checked for obscenities 
        for(i in 1:length(words)){
          
          #is_obscenity <- uni_dt5[unigram == words[i],obscenity]
          if(is_obscenity(words[i])){
            words[i] <- "output filtered for language"
          }
        }
        words
        
      }
      
      
      #### PREDICTION FUNCTIONS
      ### predictions argument is bugged so only showing user 1 prediction
      
      predict_unigram <- function(predictions = 1){
        
        # predicts unigram w/o any context
        # may consider sampling from high frequency unigrams instead of putting MLE
        # defaults to predicting one unigram but can change "predictions" parameter
        
        preds <- uni_dt5[1:predictions, unigram] # output predicted unigrams based on predictions
        
        # remove obscenities
        preds <- repl_obsc(preds)
        preds
        
        # for(i in 1:length(preds)){
        #   
        #   is_obscenity <- uni_dt5[unigram == preds[i],obscenity] == TRUE
        #   if(is_obscenity){
        #     preds[i] <- "output filtered for language"
        #   }
        # }
        # preds
        
      }
      
      predict_bigram_backoff <- function(text, predictions = 1){
        
        # predicts token completing bigram for final unigram in "text"
        
        user_input <- tolower(text) # convert user input to lowercase
        text_tokens <- tokens(user_input, remove_punct = TRUE) # clean punctuation
        text_tokens_vec <- as.character(text_tokens) # convert tokens to character vector
        last_one <- text_tokens_vec[length(text_tokens_vec)] # get last token
        
        correct_spelling <- hunspell_check(last_one) # TRUE if spelled correctly
        if(!correct_spelling){
          misspelled <- hunspell(last_one)[[1]] # misspelled word
          #top_repl <- hunspell_suggest(misspelled)  # suggestions for replacement from hunspell dictionary
          top_repl <- hunspell_suggest(last_one)  # suggestions for replacement from hunspell dictionary
          last_one <- tolower(top_repl[[1]][1])  # replace last token with top suggestion 
        }
        
        # check for obscenities or word not in corpus
        for(i in 1:length(last_one)){
          
          detected <- last_one[i] %in% uni_dt5[,unigram]
          if(!detected){ # predict unigram if word not in corpus
            return(predict_unigram())
          }
          
          if(is_obscenity(last_one[i])){
            return(print("input filtered for language")) 
            
          }
          
          
          
        }
        
        
        
        first_tok_pref <- last_one # token prefix for predictor
        format_input <- paste0("^",first_tok_pref,"_") # create search string
        
        
        pot_bigram_dt <- bi_dt5[grepl(format_input,bigram, perl = TRUE),] #  subset table with potential bigrams
        
        
        if(nrow(pot_bigram_dt) > 0){ # if bigram prefix exists (i.e data table is not empty)
          
          pot_bigram_dt[,MLE := bi_count/sum(bi_count)] # create column for MLE of suffix  
          preds <- pot_bigram_dt[1:predictions, suffix] # get suffixes with top MLEs
          
          # remove obscenities
          preds <- repl_obsc(preds)
          return(preds)
        }
        
        else{
          
          predict_unigram()
          
        }
        
      }
      
      predict_trigram_backoff <- function(text, predictions = 1){
        
        # predicts token completing trigram for final bigram in "text"
        
        
        user_input <- tolower(text) # convert user input to lowercase
        text_tokens <- tokens(user_input, remove_punct = TRUE) # clean punctuation
        text_tokens_vec <- as.character(text_tokens) # convert tokens to character vector
        
        if(length(text_tokens_vec) == 1){ 
          
          return(predict_bigram_backoff(text)) # use bigram function if there is only one token
        }
        
        
        last_two <- text_tokens_vec[c(length(text_tokens_vec)-1,length(text_tokens_vec))] # get last two tokens
        
        correct_spellings <- sapply(last_two, hunspell_check) # checks for correct spelling of last two tokens
        for(i in 1:length(last_two)){
          if(!correct_spellings[i]){
            # misspell_i <- hunspell(last_two)[[i]]
            # repl_i <- hunspell_suggest(misspell_i) # replacement options
            repl_i <- hunspell_suggest(last_two[i]) # replacement options 
            last_two[i] <- tolower(repl_i[[1]][1]) # replace misspelling with top suggestion
          }
          
        }
        
        # if(length(is_obscenity(text_tokens_vec[i]))==0){
        #   return(predict_unigram()) 
        # }
        
        # check for spelling errors
        
        for(i in 1:length(last_two)){
          
          if(length(is_obscenity(last_two[i])) == 0){ # predict unigram if word not in corpus
            return(predict_unigram())
          }
        }
        
        # check for obscenities # and missing words
        for(i in 1:length(text_tokens_vec)){
          
          if(is_obscenity(text_tokens_vec[i])){
            return(print("input filtered for language")) 
          }
        }
        
        first_tok_pref <- last_two[1] # first token in prefix
        second_tok_pref <- last_two[2] # second token in prefix
        format_input <- paste0("^",first_tok_pref,"_",second_tok_pref,"_")# format bigram for lookup
        
        
        pot_trigram_dt <- tri_dt5[grepl(format_input,trigram, perl = TRUE),] #  subset table with potential trigrams
        
        
        if(nrow(pot_trigram_dt) > 0){ # if bigram prefix exists (i.e data table is not empty)
          
          pot_trigram_dt[,MLE := tri_count/sum(tri_count)] # create column for MLE of suffix  
          preds <- pot_trigram_dt[1:predictions, suffix] # get suffixes with top MLEs
          
          # remove obscenities
          preds <- repl_obsc(preds)
          preds
        }
        
        else{  # back off if bigram prefix is not found in trigram table
          predict_bigram_backoff(text)
        }
        
      }
      
      predict_quadgram_backoff <- function(text, predictions = 1){
        
        # predicts token completing trigram for final trigram in "text"
        
        
        user_input <- tolower(text) # convert user input to lowercase
        text_tokens <- tokens(user_input, remove_punct = TRUE) # clean punctuation
        text_tokens_vec <- as.character(text_tokens) # convert tokens to character vector
        
        if(length(text_tokens_vec) == 2){ 
          
          return(predict_trigram_backoff(text)) # use trigram pred function if there are only two tokens
        }
        
        if(length(text_tokens_vec) == 1){ 
          
          return(predict_bigram_backoff(text)) # use bigram pred function if there is only one token
        }
        
        
        last_three <- text_tokens_vec[c(length(text_tokens_vec)-2, # get last three tokens
                                        length(text_tokens_vec)-1,
                                        length(text_tokens_vec))] 
        
        
        correct_spellings <- sapply(last_three, hunspell_check) # boolean. checks for correct spelling of last two tokens
        for(i in 1:length(last_three)){
          if(!correct_spellings[i]){
            # misspell_i <- hunspell(last_two)[[i]]
            # repl_i <- hunspell_suggest(misspell_i) # replacement options
            repl_i <- hunspell_suggest(last_three) # replacement options 
            last_three[i] <- tolower(repl_i[[1]][1]) # replace misspelling with top suggestion
          }
          
        }
        
        
        for(i in 1:length(last_three)){
          
          if(length(is_obscenity(last_three[i])) == 0){ # predict unigram if word not in corpus
            return(predict_unigram())
          }
        }
        
        # check for obscenities # and missing words
        for(i in 1:length(text_tokens_vec)){
          
          if(is_obscenity(text_tokens_vec[i])){
            return(print("input filtered for language")) 
          }
        }
        
        first_tok_pref <- last_three[1] # first token in prefix
        second_tok_pref <- last_three[2] # second token in prefix
        third_tok_pref <- last_three[3] # third token in prefix
        format_input <- paste0("^",first_tok_pref,"_",
                               second_tok_pref,"_",
                               third_tok_pref)# format bigram for lookup
        
        
        pot_quadgram_dt <- quad_dt5[grepl(format_input,quadgram, perl = TRUE),] #  subset table with potential quadgrams
        
        
        if(nrow(pot_quadgram_dt) > 0){ # if trigram prefix exists (i.e data table is not empty)
          
          pot_quadgram_dt[,MLE := quad_count/sum(quad_count)] # create column for MLE of suffix  
          preds <- pot_quadgram_dt[1:predictions, suffix] # get suffixes with top MLEs
          
          # remove obscenities
          preds <- repl_obsc(preds)
          preds
        }
        
        else{  # back off if bigram prefix is not found in trigram table
          predict_trigram_backoff(text)
        }
        
      }  
      
      predict_quadgram_backoff(text, predictions)
      
    }
    
    
    
    get_misspelled <- eventReactive(input$predict,{ 
      
      find_misspellings(input$user_string)
      
      })
    
    predict_text <- eventReactive(input$predict,{
      
      predict_back_off(input$user_string)
      
    })
    
    

      top_uni <- uni_dt5[1,unigram]
      top_bis <- strsplit(bi_dt5[1,bigram],"_")
      top_tris <- strsplit(tri_dt5[1,trigram],"_")
      top_quads <- strsplit(quad_dt5[1,quadgram],"_")

    output$textPred <- renderText({predict_text()})
    
    
    output$misspelled <- renderTable({get_misspelled()})
    
    # playing around with outputting options
    
     #outuput$most_common <- renderText("Most Common Words:")
     output$dt <- renderTable(
    
       data.table("Text Type" = c("single word",
                                 "pair of words",
                                 "group of three words",
                                 "group of four words"),
                 "Most Common" = c(top_uni,
                                   paste(top_bis[[1]][1],top_bis[[1]][2]),
                                   paste(top_tris[[1]][1],top_tris[[1]][2],
                                         top_tris[[1]][3]),
                                   paste(top_quads[[1]][1],top_quads[[1]][2],
                                         top_quads[[1]][3], top_quads[[1]][4])))
    
     )
    
}
