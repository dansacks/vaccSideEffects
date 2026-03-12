[note: prompt environment is a box with a solid outline and a very light
gray background]
[note: if there is an enumerate with a single elment, change to an itemize,
and enforce consistent across all enumerates on a given slide ]
Title: Integrating cladue code into research workflow.

author: Dan Sacks, PROFESSOR of Risk and Insurance

Date: March 13, 2026

Title: Integrating cladue code into research workflow.
Slide: What is claude code?
-	Claude implementation that can run commands 
o	Learn contents of your directory
o	Write code 
o	Execute code 
-	Powerful features
o	Plan mode vs. execution mode
o	Capable of independent iteration – continue until task is “done”
-	Terminal based  prefers plaintext (.tex not .doc) 
-	Non-terminal version: Claude Desktop

Slide: Example use case: 
Prompt goes a in nice math or blockquote environment: write a stata program to estimate a regression of delta against side effect beliefs in the trial, as well as indicators for prior flu vaccine experience and prior covid vaccine experience. The regression should use the main merged data set from the experiment. Execute the do file and report the coefficient on side effect beliefs in the trial and its standard error. Also report the name and file path of the do file. 
Slide: Words of warning
1.	Claude can make mistakes at scale
a.	Can mess up your entire codebase
b.	Will almost certainly screw up references 
2.	Claude may be able to access the contents of your computer and beyond
a.	Your data could end up in Anthropic’s models (though they say it won’t)
b.	Claude could use your credit card 

	Good workflow guards against these problems 

Slide: Integrating claude code into research workflow
1.	Support reproducibility
a.	Git, Make / automation 
b.	Documentation
c.	Integrate code – output – research product 
2.	Speeds up tedious or fiddly task 
a.	table output/integration
b.	git synax 
3.	Enables tasks with steep learning curves
a.	Make 
 Slide: More involved use case
Prompt goes a in nice math or blockquote environment: write a stata program to estimate a regression of delta against side effect beliefs in the trial, as well as indicators for prior flu vaccine experience and prior covid vaccine experience. The regression should use the main merged data set from the experiment. The regression results should be recorded to a table in a test_table.tex file that can be compiled into a broader document. There should be a row for each coefficient, a column for the name of the coefficient, column for the value, and column for the standard error. There should be no headers, footers, or column headings. Update manuscript/tables.tex to add a table entry that loads test_table. Compile main.tex into a pdf. The task is finished when the stata code executes, the test_table.tex has the correct content, tables.tex is updated, and main.tex compiles successfully. 

Slide: Another use case:
Prompt goes in nice math or blockquote environment: notes/claude_slides.md contains plaintext description of slides. Make a beamer presentation corresponding to those slides. Use the default theme but remove the buttons at the bottom.. 
