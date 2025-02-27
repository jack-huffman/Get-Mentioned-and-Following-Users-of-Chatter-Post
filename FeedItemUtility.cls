/**
* @File Name           :   	FeedItemUtility.apxc
* @Description         :   	Utility class for any helper or invocable methods related to FeedItems
* @Author              :   	Jack Huffman - Aleysian
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0 		02.10.2025 				Jack Huffman 			Initial Build
**/
public class FeedItemUtility {
    
    @InvocableMethod(Label='Get Mentioned and Following Users from Chatter Post' Description='Pass in a Chatter post (FeedItem) and get back a list of User IDs.' Category='Feed Item')
    public static List<Output> getMentionedAndFollowingUsersFromChatterPost(List<Input> inputs) {
        
        /* Prepare Response */
        Output response = new Output();
        List<Output> responseWrapper = new List<Output>();
        
        FeedItem item;
        // simple unwrap for list
        for(Input input : inputs) {
            item = input.item;
        }
        
        // Set to hold all User Ids that are mentioned in the post
        Set<Id> userIds = new Set<Id>(); 
        
        // Get mentioned users
        userIds.addAll(getMentionedUserIdsFromChatterPost(item));
        // Get users following the post
        userIds.addAll(getFollowingUserIdsFromChatterPost(item));
        // Query users that were mentioned or are following the post
		List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
        
        // Prepare response
        response.users = users;
        responseWrapper.add(response);
        return responseWrapper;        
    }
        
    // Function to take in a Chatter post (FeedItem) and return the UserIds of the Users mentioned in the message
    public static Set<Id> getMentionedUserIdsFromChatterPost(FeedItem item) {
        
        // Set to hold all User Ids that are mentioned in the post
        Set<Id> userIds = new Set<Id>();
        
        String communityId = Network.getNetworkId();
        List<String> feedItemIds = new List<String>{item.Id};
        
        // Re-fetch the feed items passed into the trigger
        ConnectApi.BatchResult[] results = ConnectApi.ChatterFeeds.getFeedElementBatch(communityId, feedItemIds);
    
        for (ConnectApi.BatchResult result : results) {
            if (result.isSuccess()) {
                Object theResult = result.getResult();
                if (theResult instanceof ConnectApi.FeedItem) {
                    ConnectApi.FeedItem connectItem = (ConnectApi.FeedItem) theResult;
                    for (ConnectApi.MessageSegment segment : connectItem.body.messageSegments) {
                        if (segment instanceof ConnectApi.MentionSegment) {
                            ConnectApi.MentionSegment theMention = (ConnectApi.MentionSegment) segment;
                            String mentionedId = theMention.Record.Id;
                            userIds.add(mentionedId);                                
                        }
                    }
                }
            }
        } 
        
		return userIds;
    }

	// Function to take in a Chatter post (FeedItem) record and return a list of Users following the record    
    public static Set<Id> getFollowingUserIdsFromChatterPost(FeedItem item) {
        Set<Id> userIds = new Set<Id>();
        List<EntitySubscription> subs = [SELECT SubscriberId FROM EntitySubscription WHERE ParentId = :item.ParentId];
        if(!subs.isEmpty()) {
            for(EntitySubscription sub : subs) {
                userIds.add(sub.SubscriberId);
            }
        }        
        return userIds;
    }
    
    public class Input {
        @InvocableVariable(Label='Feed Item Record' required = true)
        public FeedItem item;
    } 
    
    public class Output {
        @InvocableVariable(label='Mentioned Users from FeedItem')
        @AuraEnabled
        public List<User> users;
    }
}