##  MIT LICENSE BEGIN
###############################################################################
#                                                                             #
# Copyright Embracket (www.embracket.com) 2023                                #
#                                                                             #
# Permission is hereby granted, free of charge, to any person obtaining a     #
# copy of this software and associated documentation files (the “Software”),  #
# to deal in the Software without restriction, including without limitation   #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,    #
# and/or sell copies of the Software, and to permit persons to whom the       #
# Software is furnished to do so, subject to the following conditions:        #
#                                                                             #
# The above copyright notice and this permission notice shall be included in  #
# all copies or substantial portions of the Software.                         #
#                                                                             #
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         #
# DEALINGS IN THE SOFTWARE.                                                   #
#                                                                             #
###############################################################################
##  MIT LICENSE END

### DOCUMENTATION BEGIN

# NOTE: THIS SCRIPT CAN ONLY BE USED IF THE FOLLOWING PREREQUISITES ARE MET:
## - File follows the format testtype_subtype[...].csv
### The [...] can be anything, the script will still work as intended
## - Input file is CSV format and has two columns (should not be a problem if 
##   you use the given tshark script)

### Command to get CSV files
# tshark -r <PATH TO PCAPNG> -o 'gui.column.format: "Absolute Time", %Yt, "Bytes", "%L"'> <PATH TO CSV>
# %Yt --- the absolute time, which makes sure both graphs are in sync, 
# %L  --- bytes per packet which we can use to calculate speeds
# Labels are arbitrary and could be anything
# You can use the included shell script if you'd like

### USAGE
# Rscript <PATH TO THIS SCRIPT> <FILES>

### DOCUMENTATION END

### LIBRARIES
# You might need to install more than these, I'm not sure.
                   # For
library(dplyr)     #  -  processing dataframes
library(ggplot2)   #  -  plotting graphs
library(stringr)   #  -  making titles
library(lubridate) #  -  handling time
library(tidyr)     #  -  tidying dataframes

### Settings
# The names of the columns (seperated by spaces in .csv file)
col.names <- c( "date", "time", "bytes" )  
# Add colors for nth graph in each figure
               #Colorset (Line color, Fill color)
colors <- list(c(         "#538E2A",  "#649F3B"), c("#89664B", "#79553A")) 
# Overlay opacity 
opacity <- 0.4
# Set dimensions for graph here
                # Height, Width
dimensions <-   c(4,      7)          
# Set unit prefix here
unit <- 1000
# Set interval here (in terms of seconds)
interval <- 0.125 # It seems to prefer values like 0.125, 0.250, e.t.c... idk why ???
# Set x-axis breaks here
breaks <- "2 secs"
# Set labels accordingly here
xlab <- "Seconds"
ylab <- "Kilobytes (per 125 milliseconds)"
###



################################################################################



### Code, only touch if you know what you're doing
args <- commandArgs(trailingOnly = TRUE)  # Grabs file arguments
#args <- c("../Obehandlad data/Filtrerade/start_server.pcapng.csv")
types <- gsub("(.*/)|(_.*)|(.csv)", "", args)    # Grabs the test type (part before first _) for each file

argsTypes <- data.frame(arg = args,type = types) # Dataframe to ease sorting
argsTypes <- argsTypes[order(argsTypes$type),]   # Sorting dataframe by type of test
argsTypes <- argsTypes[order(argsTypes$arg),]    # Sorting dataframe by subtype

tests <- split(argsTypes$arg, argsTypes$type)    # Splits all files into groups based on test
print(tests)

earliest <- ymd_hms(now())
read_test <- function(test){                   # Function for reading test CSVs
  tdf <- read.table(test, col.names=col.names) # Reads corresponding CSV file 
  tdf <- unite(tdf, datetime, c(date, time))   # Puts date and time back together
  tdf$datetime <- ymd_hms(tdf$datetime)        # Formats time
  earliest <<- pmin(tdf$datetime[1], earliest)  # Sets earlier time if available
  tdf$datetime <- floor_date(tdf$datetime, paste(interval*2,"secs",sep="")) # Splits time into periods

  tdf <- tdf %>%
    complete(datetime = full_seq(datetime, interval*2), bytes = 0) %>% # Complete dataset so it is continuous
    group_by(datetime) %>%                                             # Groups data into intervals
    summarize(bytes = sum(bytes)/1000)                                 # Sums bytes over those intervals correspondingly and divides by 1000
  outTest <<- tdf
  tdf
  }

testNum <- 1

for (test in tests) {                                 # For every test
  earliest <- ymd_hms(now())                          # Resets earliest time (always set to current)
  testType <- gsub("(.*/)|(_.*)|(.csv)", "", test[1]) # Grabs test type from first file (since both are the same anyway)
  title <- gsub("-", " ", testType)
  title <- str_to_title(title)                        # Automatically creates a title from file name
  print("##################################################################")
  print(paste("Processing test", testNum, "---", title, sep=" "))
  print(test)                                         # Prints files for debugging
  
  # Basic plot setup
  plot <- ggplot() + xlab(xlab) + ylab(ylab) + ggtitle(title) 
  
  for (n in length(test):1){                          # For every subtest
    color <- c("black", "darkgrey")                   # Default colors
    if (n <= length(colors) && length(test) != 1){    # If there are enough colors and it's not a single test
      color <- colors[[n]] }                          # Set the colors to  preferred otherwise default
    print(paste("Test", test[n], "has colours", color[1], "and", color[2], sep=" "))
    plot <- plot + geom_area(                         # Adds another geom_area to the plot
      data   = read_test(test[n]),                    # Generate test data
      aes(x=datetime, y=bytes),                       # Sets what the axis' represent
      colour = color[1],                              # Set colors e.t.c.
      fill   = color[2], 
      alpha  = opacity,
    ) 
  }
  labels = function(x) round(difftime(x, earliest)) # Uses the difference in time from the earliest time out of the graphs to set the x-axis relatively
  plot <- plot + scale_x_datetime(breaks=breaks, labels=labels, expand=c(0,0)) # Sets the breaks, the labeling and sets origin to 0,0

  print(plot) # For R studio
  filename <- paste(testType, ".png", sep="") # Creates file name, with .png extension
  print(ggsave(filename, height = dimensions[1], width = dimensions[2])) # Saves the file, and also prints it (for logging)
  testNum <- testNum + 1 # Increases the index for prints
}


  
