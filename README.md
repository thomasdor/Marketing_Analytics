# Predicting the futur donators of a charity 

In this Github, you can find the work I did in the context of my Marketing Analytics course at Essec & Centrale Supelec. We used SQL and R in this project. 
The databases used for this project can be downloaded using the pdf in the folder "Databases" of this repository.
The first assignment just consisted in exploring the charity database through SQL and present the most interesting graph thanks to Excel or Python. It was a group assignment that I did with four other comrades from India and China. The final ppt and the guidelines of this assignment can be found in the folder of the assignment 1.
The second assignment -individual- consisted in building a scoring model to know who to contact for the next fundraising campaigns of the charity. To do so, I built the model in two steps. The first one was to predict who will donate thanks to a Logit model, based on certain features I created (date of last donation, geographic location, sex, etc.): each individual of the database was therefore assigned a probability of donating. The second part was to predict how much people will donate in case of donation. I used a linear regression to do so and a potential amount was assigned to every donators. The expected amount of each individuals was computed by multiplying the probability of donation with the potential amount of donation. The final code and the guidelines of this assignment can be found in the folder of the assignment 2.
Contrary to assignment 2 where the goal was to predict who will donate for the next fundraising campaign, the third assignment consisted in setting up a long-term solicitation strategy to know who to sollicitate and how often throughout the year.

Working only on a fraction of the database -that is to say on the small database-, we decided to give a score to each individual to know if it was worth sollicitating him for the next year. To do so, we first computed the customer lifetime value of each individual in the database for the ten years to come, with the following formula

<img src="https://render.githubusercontent.com/render/math?math=\sum_{i=1}^{10} \frac{AVGAMOUNT* Freq_i}{(1%2Br)^i} ">

Where :

1)	AVG AMOUNT is the average amount per donation for the customer. It is estimated trough a XGboost model in our code, based on different features (location, frequency of donation, etc.)

2)	r  is the discount rate (r = 0.1) 

3)	Fr_i is the expected frequency of donation for the year i. It is computed by making the difference between the expected transactions for the ith year and the i-1th year thanks to the BTYD package (see code).

Good reading !







