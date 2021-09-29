# Error framework plugin for Kong

## Description

<b>Error Framework</b> is a [Kong](https://getkong.org/) plugin, which help customize and unify the error framework across the gateway. You can standardize the error framwork irrespective of how your provider handles their error structures. This plugin can be associated to service/consumer/cluster based on the use case.

## Error Message format
![image](https://user-images.githubusercontent.com/45583515/135211399-443abfc8-39a6-4727-ab53-8d992d9ea38a.png)



## Configurations
### Plugin properties

| **Properties**        | **Type**          | **Description**  |
| ------------- |:-------------:| :-----|
| error.values   | Array of Strings | *It should follow the below pattern* <br/> errorstatus_{YOUR-ERORR-CODE},message_{YOUR-ERROR-MESSAGE},detail_{YOUR-ERROR-DETAIL},system_{ERROR-ORIGINATING-SYSTEM} <br/> errorstatus_{YOUR-ERORR-CODE},message_{YOUR-ERROR-MESSAGE},detail_{YOUR-ERROR-DETAIL},system_{ERROR-ORIGINATING-SYSTEM} 
| targeterror.values     | Array of Strings      |   *It should follow the below pattern* <br/> errorstatus_{YOUR-ERORR-CODE},messagepath_{UPSTREAM-ERROR-MESSAGE-JSONPATH},detailpath_{UPSTREAM-ERROR-DETAIL-JSONPATH},system_{UPSTREAM-SYSTEM}<br/> errorstatus_{YOUR-ERORR-CODE},messagepath_{UPSTREAM-ERROR-MESSAGE-JSONPATH},detailpath_{UPSTREAM-ERROR-DETAIL-JSONPATH},system_{UPSTREAM-SYSTEM}
| defaulterror | string      |   *It should follow the below pattern* <br/> message_{YOUR-DEFAULT-ERROR-MESSAGE},detail_{YOUR-DEFAULT-ERROR-DETAIL}  |


## Description and usage

config.error.values (Optional)

This has a very specific format in which you provide the input. Note that this is an array, there can be multiple lines of the same with the different HTTP error codes

 errorstatus_{YOUR-ERORR-CODE},message_{YOUR-ERROR-MESSAGE},detail_{YOUR-ERROR-DETAIL},system_{ERROR-ORIGINATING-SYSTEM}
 Example : errorstatus_401,message_UNAUTHORIZED,detail_Invalid accesss token,system_Upstreamsystem1

Only the details in the curly braces {} should be modified

{YOUR-ERORR-CODE} - The error code which you want to customize. These are http error codes.

errorstatus_401
errorstatus_500

Note : Do not include _ or , in your values as they are used as tokenizers

{YOUR-ERROR-MESSAGE} - Error message you want to supply for the above error code. You can provide the values that correspond to the http error code.
Example : 

errorstatus_401,message_UNAUTHORIZED
errorstatus_400,message_BAD REQUEST

Note : Do not include _ or , in your values as they are used as tokenizers

{YOUR-ERROR-DETAIL} - Detailed error mesage for the error code. 
Example : 

errorstatus_401,message_UNAUTHORIZED,detail_Invalid accesss token
errorstatus_400,message_BAD REQUEST,detail_Incorrect message_Incorrect payload

Note : Do not include _ or , in your values as they are used as tokenizers

{ERROR-ORIGINATING-SYSTEM} - This value helps determine where the error occurs. Provide the upstream system name here

Example : 

errorstatus_401,message_UNAUTHORIZED,detail_Invalid accesss token,system_Upstreamsystem1
errorstatus_400,message_BAD REQUEST,detail_Incorrect message_Incorrect payload,system_Upstreamsystem1



config.targeterror.values  (Optional)

This has a very specific format in which you provide the input. You will be using this if you want to send the upstream error messsage/error detail/custom code back to the consumer. Note that this is an array, there can be multiple lines of the same ,with the different HTTP error codes of the upstream.

 errorstatus_{YOUR-ERORR-CODE},messagepath_{UPSTREAM-ERROR-MESSAGE-JSONPATH},detailpath_{UPSTREAM-ERROR-DETAIL-JSONPATH},system_{UPSTREAM-SYSTEM}
 Example : errorstatus_401,messagepath_error.title,detail_error.detail,system_Upstreamsystem1

Only the details in the curly braces {} should be modified

{YOUR-ERORR-CODE} - The error code which you want to customize. These are http error codes.

errorstatus_401
errorstatus_500

Note : Do not include _ or , in your values as they are used as tokenizers

{UPSTREAM-ERROR-MESSAGE-JSONPATH} - Provide the JSON PATH of the error message in your upstream response. This plugin will retrieve  BAD REQUEST from the below payload
Example : 
errorstatus_401,messagepath_error[1].title

Note : Do not include _ or , in your values as they are used as tokenizers

{UPSTREAM-ERROR-DETAIL-JSONPATH} - Provide the JSON PATH of the error detail in your upstream response.

Example : 
errorstatus_401,messagepath_error.title,detail_error.detail
In the above example the upstream system sends the error message in the below path. This plugin will retrieve  "incoorect payload" from the below payload
{
    error:
        detail: "incoorect payload",
        title: "BAD REQUEST"

}

Note : Do not include _ or , in your values as they are used as tokenizers

{ERROR-ORIGINATING-SYSTEM} - This value helps determine where the error occurs. Provide the upstream system name here

Example : 
errorstatus_{YOUR-ERORR-CODE},messagepath_{UPSTREAM-ERROR-MESSAGE-JSONPATH},detailpath_{UPSTREAM-ERROR-DETAIL-JSONPATH}



defaulterror (required)

This is a required parameter, which has similar formating as the above fields. If none of the error matches the plugin will instruct KONG to use the below error message and detail.
message_{YOUR-DEFAULT-ERROR-MESSAGE},detail_{YOUR-DEFAULT-ERROR-DETAIL} 
Example : message_Default error message ,detail_default system error

Note : Do not include _ or , in your values as they are used as tokenizers
