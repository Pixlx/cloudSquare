@RestResource(urlMapping='/external/applications/*')
global without sharing class ApplicationWebhook {

    @HttpPost
    global static void handlePost() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try{

            ApplicationDTO application = (ApplicationDTO)JSON.deserialize(RestContext.request.requestBody.toString(),ApplicationDTO.class);
            application.source = 'Webhook';

            ApplicationResult result = ApplicationProcessingService.processApplication(application);

            res.responseBody = Blob.valueOf(JSON.serialize(result));
            res.statusCode = result.success ? 200 : 400;
        }
        catch(Exception e){
            
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error');
            
        }
    }
}