Due to changes (OAUTH) on the Strava API this won't work anymore. I am looking for a solution.

Compares the segment times off all your rides with all your friends.

1. Checkout repo
2. Put your access token for the strava api in a file named 'access_token.txt' directly in the checked out repo
3. Call compare.rb

Maybe a "Rate Limit Exceeded" is thrown from the Strava web page. In
this case the ruby script waits 1500 seconds and continues.
