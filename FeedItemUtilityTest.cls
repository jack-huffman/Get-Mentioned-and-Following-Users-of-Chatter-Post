/**
* @File Name           :   	FeedItemUtilityTest.apxc
* @Description         :   	Test class for FeedItemUtility
* @Author              :   	Jack Huffman - Aleysian
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0 		02.25.2025 				Jack Huffman 			Initial Build
**/
@isTest
public class FeedItemUtilityTest {
    	
    // SeeAllData required for ConnectApi methods
    @isTest(SeeAllData = true)
    public static void test() {
        
        Id rtid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Platform_Vendor').getRecordTypeId();
        Account a = new Account(Name = 'Test Account', AccountNumber = '123', AnnualRevenue = 1000000, Website = 'https://aleysian.com', Type = 'Type1', Description = 'D1', RecordTypeId = rtid);
        insert a;
        
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User u = new User(Username = 'test@provi.com', Email = 'test@provi.com', FirstName = 'Test', LastName = 'User', CommunityNickname = 'Test', LocaleSidKey = 'en_US', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8', Alias = 'tu', ProfileId = profiles[0].Id);
        insert u;
        
        // Have user follow the account
        ConnectApi.Subscription subscriptionToRecord = ConnectApi.ChatterUsers.follow(null, u.Id, a.Id);
        
        // Create chatter post programmatically to properly create mention to user
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        mentionSegmentInput.Id = u.Id;
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        textSegmentInput.text = 'Testing';
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        feedItemInput.Body = messageBodyInput;
        feedItemInput.FeedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.SubjectId = a.Id;
        
        // Properly post feedElement to have mention stick
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);

		// Use feedElement to get the corresponding FeedItem record
		FeedItem item = [SELECT Id, ParentId FROM FeedItem WHERE Id = :feedElement.Id LIMIT 1];
        // Prepare invocable apex input
        FeedItemUtility.Input input = new FeedItemUtility.Input();
        input.item = item;
        List<FeedItemUtility.Input> inputs = new List<FeedItemUtility.Input>();
        inputs.add(input);
        
		List<FeedItemUtility.Output> outputs = FeedItemUtility.getMentionedAndFollowingUsersFromChatterPost(inputs);
		Assert.isTrue(!outputs.isEmpty(), 'A FeedItemUtility.Output list should have been returned.');  
        List<User> users = outputs[0].users;
        Assert.isTrue(!users.isEmpty(), 'There should have been at least one User returned from the apex method.');
    }
}