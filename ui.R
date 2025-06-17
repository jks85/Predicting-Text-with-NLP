# UI for Ngram Prediction App. Capstone Project


library(shiny)

# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("Predicting Text"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        
        sidebarPanel(
            
            # h4("This app tries to predict your next word."),
            # h4("Type a sentence or a phrase in the
            #    box to the right. Tip: The app runs faster with shorter sentences/phrases "),
            HTML("This app predicts your next word and checks spelling. <br>
                 <br>
                 1. Type a sentence or phrase in the textbox to the right. <br>
                 2. Click the button to see the prediction. <br>
                 <br>
                 Tip: The app runs faster with shorter sentences/phrases.")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            
              textInput(inputId = "user_string", label = "Type something here:"),
              h4(" "),
              actionButton(inputId = "predict",
                           label = "Predict"),
              HTML(" <br>"),
              HTML(" <br>"),
              HTML("Next Word: <br>"),
              textOutput("textPred"),
              HTML(" <br>"),
              HTML(" <br>"),
              HTML(" Misspelled Inputs:"),
              HTML(" <br>"),
              HTML(" <br>"),
              tableOutput("misspelled"),
              HTML("Most Common Words Overall: <br>"),
              tableOutput("dt")
              
        )
    )
)
