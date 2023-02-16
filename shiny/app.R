library(shiny)
library(rblncr)
library(dplyr)

ui <- fluidPage(titlePanel("Rblncr Interactive Demo"),
                sidebarLayout(
                  sidebarPanel(
                    h4("Credentials"),
                    selectInput("trading_mode", "Trading Mode", c("paper", "live")),
                    textInput("alpaca_key", "Alpaca Key", "Enter Key Here"),
                    passwordInput("alpaca_secret", "Alpaca Secret"),
                    br(),
                    h4("Portfolio Targets"),
                    sliderInput("tolerance", "Tolerance %", 0, 100,5, step = 1),
                    sliderInput("cash_pct", "Cash %", 0, 100,100, step = 1),
                    sliderInput("cooldown", "Cooldown Days", 0, 365, 30, step = 1),
                    width = 3
                    
                  ),
                  mainPanel(
                            
                            
                            
                            tabsetPanel(type = "tabs",
                                        tabPanel("Balances", 
                                                 br(),
                                                 actionButton("go", "Check Balances"),
                                          tableOutput("cash"),
                                          tableOutput("assets")
                                          
                                          ))
                            ),
                  
                  
                ))



server <- function(input, output) {
  ### Verify IO
  output$trading_mode <- renderText({
    input$trading_mode
  })
  output$alpaca_key <- renderText({
    input$alpaca_key
  })
  output$alpaca_secret <- renderText({
    req(input$go)
    isolate(input$alpaca_secret)
  })
  
  ### Get portfolio current ####
  portfolio_current <- reactive({
    # blocking button
    req(input$go)
    
    # connection credentials
    t_conn <- alpaca_connect(input$trading_mode, 
                   input$alpaca_key, 
                   input$alpaca_secret)
    
    d_conn <- alpaca_connect('data',
                           input$alpaca_key, 
                           input$alpaca_secret)

    # dummy portfolio
    dummy_portfolio <- create_portfolio_model(name = "dummy_portfolio",
                           description = "a 100% cash portfolio for valuation purposes",
                           cash = list(percent = input$cash_pct),
                           assets = data.frame(symbol = character(), 
                                               percent = numeric()),
                           tolerance = list(percent = input$tolerance),
                           cooldown = list(days=input$cooldown))
    
    get_portfolio_current(t_conn) |>   
      load_portfolio_targets(dummy_portfolio) |>
      price_portfolio(connection = d_conn, price_type = 'close')
    
    })
  
  output$cash <- renderTable({input$go
                             result = isolate(portfolio_current())
                             result$cash })
  output$assets <- renderTable({input$go
    result = isolate(portfolio_current())
    result$assets })
  
  ### END Get portfolio current ###
  
}

shinyApp(ui, server)
