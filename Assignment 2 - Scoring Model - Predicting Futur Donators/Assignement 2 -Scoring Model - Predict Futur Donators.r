library(RODBC)
library(ggplot2)
library(DataExplorer)
library(nnet)
library(caret)
library(data.table)
library(mltools)
library(randomForest)
library(dplyr)
library(stringr)
library(e1071)
library(tidyverse)

# Connect to MySQL (my credentials are mysqlodbc/root/root)
#db = odbcConnect("mysql_server_64", uid="root", pwd="")
db = odbcConnect("my_sql_marketing", uid="root",pwd = "rineau85!")
sqlQuery(db, "USE ma_charity_full")

# initial database
query1 = "SELECT a.contact_id, a.donation, a.calibration, 
		case when DATEDIFF(20180626,MAX(b.act_date))/365 IS NULL then 0 else DATEDIFF(20180626,MAX(b.act_date))/365 end as 'recency',
		case when COUNT(b.amount) IS NULL then 0 else COUNT(b.amount) end as 'frequency',
        case when AVG(b.amount) IS NULL then 0 else AVG(b.amount) end as 'avgamount',
        case when MAX(b.amount) IS NULL then 0 else MAX(b.amount) end AS 'maxamount',
        case when b.payment_method_id IS NULL then 'missing' else b.payment_method_id end as pay_met
        FROM assignment2 a
LEFT JOIN acts as b
ON a.contact_id = b.contact_id
LEFT JOIN contacts as c
ON a.contact_id = c.id
GROUP BY 1;"
data_start = sqlQuery(db, query1)

# zip code and region name
query2 = "SELECT a.contact_id,
        LEFT(c.zip_code,2) as zip_short, 
        CASE when left(c.zip_code,2) in (75,93,92,94,95,78,91,77) then 'Ile de France'
        when left(c.zip_code,2) in (29,22,56,35) then 'Bretagne'
        when left(c.zip_code,2) in (05,04,06,83,13,84) then 'Provence Alpes Cote dAzur'
        when left(c.zip_code,2) in (50,14,61,27,76) then 'Normandie'
        when left(c.zip_code,2) in (08,51,55,10,52,88,68,67,54,57) then 'Grand Est'
        when left(c.zip_code,2) in (89,21,70,25,39,71,58,90) then 'Bourgogne Franche Comte'
        when left(c.zip_code,2) in (28,45,41,37,36,18) then 'Centre Val de Loire'
        when left(c.zip_code,2) in (00,44,53,72,49,85) then 'Pays de la Loire'
        when left(c.zip_code,2) in (17,79,86,87,23,16,24,19,33,47,40,64) then 'Nouvelle Aquitaine'
        when left(c.zip_code,2) in (46,82,12,48,30,81,34,11,66,09,31,65,32) then 'Occitanie'
		    when left(c.zip_code,2) in (62,59,80,60,02) then 'Hauts de France'
        when left(c.zip_code,2) in (03,63,15,43,42,69,01,74,73,38,26,07) then 'Auvergne Rhone Alpes'
        when left(c.zip_code,2) in (20) then 'Corse'
        when left(c.zip_code,2) in (98,97) then 'Outre Mer'
        when c.zip_code = 'NA' then 'Others'
        when c.zip_code is NULL then 'Others'
        else 'Others'
		end zip_dep
 FROM assignment2 a
 LEFT JOIN contacts as c
 ON a.contact_id=c.id"
 
data_zip = sqlQuery(db, query2)

# is pa or not
query3 = "SELECT 
    assignment2.contact_id, IF(nb_pa IS NULL, 0, 1) AS 'is_pa'
FROM
    assignment2
        LEFT JOIN
    (SELECT 
        contact_id, COUNT(id) AS 'nb_pa'
    FROM
        acts
    WHERE
        (acts.act_date >= 20170626)
            AND (acts.act_date < 20180626)
            AND act_type_id = 'PA'
    GROUP BY contact_id) AS a ON a.contact_id = assignment2.contact_id;"

data_pa= sqlQuery(db, query3)

# number of campaign sollicitations
query4 = "SELECT contact_id, count(campaign_id) as campaign_solicitations
          from actions
          where action_date>20130626
          group by contact_id;"

data_sol = sqlQuery(db, query4)

# number of donations where the contact gave when specifically contacted by a campaign + average donation for this campaign
query5 = "select contact_id,
	case when count(campaign_id) IS NULL then 0 else count(campaign_id) end as tw_number_of_campaign_reactions,
    case when avg(amount) IS NULL then 0 else avg(amount) end as tw_average_campaign_donation
    from (select contact_id,
                 campaign_id,
                 act_date,
                 avg(amount) as amount
          from acts
          where act_date >= 20130626 and act_date < 20180626
          group by contact_id, campaign_id) as acts
          where acts.campaign_id is not NULL
    group by contact_id;"

data_resp = sqlQuery(db, query5)

# male or female
query6 = "SELECT id,
        CASE when prefix_id = 'MR' then 'male'
        when prefix_id = 'MME' then 'female'
        when prefix_id = 'MLLE' then 'female'
        when prefix_id = 'NA' then 'unknown'
        when prefix_id IS NULL then 'unknown'
        else 'unknown'
        end prefix_cat
FROM contacts
GROUP BY id;"

data_prefix = sqlQuery(db, query6)

query7 = "SELECT a.contact_id, a.donation, a.calibration, a.amount as targetamount,
        case when AVG(b.amount) IS NULL then 0 else AVG(b.amount) end as 'avgamount',
        case when MAX(b.amount) IS NULL then 0 else MAX(b.amount) end AS 'maxamount'
        FROM assignment2 a
LEFT JOIN acts as b
ON a.contact_id = b.contact_id
GROUP BY 1;"
data1 = sqlQuery(db, query7)



# Close the connection
odbcClose(db)

# just count NA value for each column of the different datasets
data_zip %>% summarise_all(~ sum(is.na(.)))
data_prefix %>% summarise_all(~ sum(is.na(.)))
data_sol %>% summarise_all(~ sum(is.na(.)))
data_resp %>% summarise_all(~ sum(is.na(.)))

#data merge
data = merge(data_start, data_pa, by="contact_id", all.x = TRUE)
data = merge(data, data_sol, by="contact_id", all.x = TRUE)
data = merge(data, data_resp, by="contact_id", all.x = TRUE)
data = merge(data, data_zip, by="contact_id", all.x = TRUE)
data = merge(data, data_prefix, by.x="contact_id", by.y="id", all.x = TRUE)

data %>% summarise_all(~ sum(is.na(.)))


#clean missing values
data$tw_number_of_campaign_reactions[is.na(data$tw_number_of_campaign_reactions)] <- 0
data$tw_average_campaign_donation[is.na(data$tw_average_campaign_donation)] <- 0
data$zip_short <- as.character(data$zip_short)
data$zip_short[is.na(data$zip_short)] <- 'missing'


#one hot encoding
data_encoded = one_hot(as.data.table(data), c('pay_met', 'prefix_cat', 'zip_short', 'zip_dep'))
data_encoded <- data.frame(data_encoded, row.names = 1)

# withdraw useless column zip_short (failed encoding)
data_encoded = data_encoded[,-18]

#final data
data_final_prob = data_encoded[data_encoded$calibration == 1,] # training set (discrete model)
data_final_prob_test = data_encoded[data_encoded$calibration == 0,] # test set (discrete model)
data_final_amount = data_final_prob[data_final_prob$donation == 1,] # most likely donation in amount (continuous)


# withdraw calibration
data_final_prob = data_final_prob[,-2]
data_final_amount = data_final_amount[,-2]
data_final_prob_test = data_final_prob_test[,-2]

# check NA values
data_final_prob %>% summarise_all(~ sum(is.na(.)))

#MODEL!!!!

# Compute the logit model on the entire data set
# These are the predictions you need to use later on
#formula = "donation ~ (recency * frequency) + log(recency) + log(frequency)"
model = multinom(donation ~., data=data_final_prob)

# Run a nfold cross-validation
nfold = 5
nobs  = nrow(data_final_prob)
index = rep(1:nfold, length.out = nobs)
probs = rep(0, nobs)
for (i in 1:nfold) {
  
  # Assign in-sample and out-of-sample observations
  insample  = which(index != i)
  outsample = which(index == i)
  
  # Run model on in-sample data only / training on the insample
  submodel = multinom(donation ~., data_final_prob[insample, ])
  
  # Obtain predicted probabilities on out-of-sample data / testing on the outsample
  probs[outsample] = predict(object = submodel, newdata = data_final_prob[outsample, ], type = "probs")
}

# Print cross-validated probabilities
print(head(probs))

# probs = resulting probabilities of the cross-validation
View(probs)

# How many loyal donors among the top 2000
# in terms of (out-of-sample) probabilities?
pred = data.frame(model = probs, truth = data_final_prob$donation) # probability versus reality
pred = pred[order(pred$model, decreasing = TRUE), ] # just put probs in descending order to better visualize
print(sum(pred$truth[1:2000]) / 2000) # see the proportion of real donors among the  first 2000 most probable donors according to the logit

# vs. full model used to make actual predictions : no cross-validation here, only training 
probs = predict(object = model, newdata = data_final_prob, type = "probs")
pred = data.frame(model = probs, truth = data_final_prob$donation)
pred = pred[order(pred$model, decreasing = TRUE), ]
print(sum(pred$truth[1:2000]) / 2000) # quite the same result

# Logit model
model = multinom(formula = donation ~., data = data_final_prob)

# Obtain predictions (on the same data set)
probs  = predict(object = model, newdata = data_final_prob, type = "probs")
View(probs)

# Rank order target variable in decreasing order of (predicted) probability
target = data_final_prob$donation[order(probs, decreasing=TRUE)] / sum(data_final_prob$donation) 
# above, we have the list of donators and non-donators (1 or 0) in decreasing order of probs divided by the nbr of guys who donated
gainchart = c(0, cumsum(target))
# View(gainchart)
# cumsum function returns a vector whose elements are the cumulative sums of the elements of the arguments

# Create a random selection sequence
random = seq(0, to = 1, length.out = length(data_final_prob$donation)) # n-length number between start (here 0) and end (here 1)

# Create the "perfect" selection sequence
perfect = data_final_prob$donation[order(data_final_prob$donation, decreasing=TRUE)] / sum(data_final_prob$donation)
# show donation / sum of donations in decreasing order
perfect = c(0, cumsum(perfect))
# same thing in cumulative probability

# Plot gain chart, add random line
plot(gainchart) # donations made according to our prediction; it's not perfect should be astraight line and then horizontal one if our
# decreasing probs ranked the contact well, at least it is not bad as it is concave
lines(random) # donations with the right order
lines(perfect) # when everybody have the same probability of giving 

# Compute 1%, 5%, 10%, and 25% lift and improvement
q = c(0.01, 0.05, 0.10, 0.25)
x = quantile(gainchart, probs = q) # show the cumulated prob at a given percentage of donors for the gainchart (50% =>30 000 : 0.83)
z = quantile(perfect, probs = q) # show the cumulated prob at a given percentage of donors for the perfect situation 

print("Hit rate:") # hit rate, sucess rate
print(x) # typically at 25% of the list gain chart you have  60% of the donors, which the most 25% probable donors represent 60% of the
# real donors
print("Perfect rate:") 
print(z) # typically at 25% of the list perfect you have  100% of the donors which make sense because donors 10% of the calibration/
# training set
print("Lift:") 
print(x/q) # the probability divided by the proportion of donors : the first quantile will have a very high lift and precisely select
# the donors, this diminishes as we enlarge the proportion : probability are less sure/precise
print("Improvement:") # potential improvement 
print((x-q)/(z-q))
print("Improvement:") # potential improvement 
print((x)/(z))

# final prediction
data_final_prob_test$probs = predict(object=model, newdata = data_final_prob_test, type='probs')

###################################################################################
#predict amount
 # reminder : data1 : 120 000 entries 
data2 = data1[data1$calibration ==1,]
data3 = data2[data2$donation == 1,]

amount.model = lm(formula = log(targetamount) ~ log(avgamount) + log(maxamount),
                  data = data3) # linear regression with only two explanatory variables 

newdata = data1[data1$calibration ==0,] # test data

out = data.frame(contact_id = newdata$contact_id)
out$amount = exp(predict(object = amount.model, newdata = newdata)) # amount expected for the test data

out$predict = out$amount * data_final_prob_test$probs # scoring model : computation of the expected value

z = which(out$predict > 2)  # z is the final output
print(length(z))

##########################################################
Export

out$solicit = ifelse(out$predict > 2, 1, 0)

export = out[,-2:-3]
export <- data.frame(export, row.names = 1)

write.table(export, file="Marketing Analytics.csv", sep="\t")
