# Predicting the futur donators of a charity 

In this Github, you can find the work I did in the context of my Marketing Analytics course (Master in Data Science & Business Analytics -Essec Business School & CentraleSuplec in France-). We used SQL and R in this project.

The databases used for this project can be download using the pdf in the folder "Databases" of this repository.

The first assignment consisted in exploring a database through SQL and present the most interesting graph thanks to Excel or Python. It was a group assignment that I did with four of my fellow comrades, Taneja Ankisetty, Prannoy Bhumana Priyanka Pippiri  (from India), and Xiangyu Wang (from China). The final ppt and the guidelines of this assignment can be found in the 
folder of the assignment 1.

The second assignment -individual- consisted in building a scoring model to know who to contact for the next fundraising campaigns of the charity. To do so, I built the model in two steps. The first part was to predict who will donate thanks to a Logit model, based on certain features I created (date of last donation, geographic location, sex, etc.). At the end of this first step, each individual of the database was assigned a probability of donating. The second part was to predict how much people will donate in case of donation. I used a linear regression to do so and a potential amount was assigned to every donators. The expected amount of each individuals was computed by multpilying the probability of donation with the potential amount of donation. The final code and the guidelines of this assignment can be found in the 
folder of the assignment 2.
<img src="https://render.githubusercontent.com/render/math?math=\sum_{i=1}^{10} \frac{AVGAMOUNT* Freq_i}{(1 - r)^i} ">
Good reading !







