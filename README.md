# DocuSign PowerShell Code Examples

## Introduction
This repo includes a powershell command-line application to demonstrate:

## eSignature API

For more information about the scopes used for obtaining authorization to use the eSignature API, see the [Required Scopes section](https://developers.docusign.com/docs/esign-rest-api/esign101/auth)

1. **Use embedded signing.**
   [Source.](./eg001EmbeddedSigning.ps1)
   This example sends an envelope, and then uses embedded signing for the first signer.
   With embedded signing, the DocuSign signing is initiated from your website.
1. **Request a signature by email (Remote Signing).**
   [Source.](./examples/eSignature/eg002SigningViaEmail.ps1)
   The envelope includes a pdf, Word, and HTML document.
   Anchor text ([AutoPlace](https://support.docusign.com/en/guides/AutoPlace-New-DocuSign-Experience)) is used to position the signing fields in the documents.
1. **List envelopes in the user's account.**
   [Source.](./examples/eSignature/eg003ListEnvelopes.ps1)
1. **Get an envelope's basic information.**
   [Source.](./examples/eSignature/eg004EnvelopeInfo.ps1)
   The example lists the basic information about an envelope, including its overall status.
1. **List an envelope's recipients** 
   [Source.](./examples/eSignature/eg005EnvelopeRecipients.ps1)
   Includes current recipient status.
1. **List an envelope's documents.**
   [Source.](./examples/eSignature/eg006EnvelopeDocs.ps1)
1. **Download an envelope's documents.** 
   [Source.](./examples/eSignature/eg007EnvelopeGetDoc.ps1)
   The example can download individual
   documents, the documents concatenated together, or a zip file of the documents.
1. **Programmatically create a template.**
   [Source.](./examples/eSignature/eg008CreateTemplate.ps1)
1. **Request a signature by email using a template.**
   [Source.](./examples/eSignature/eg009UseTemplate.ps1)
1. **Send an envelope and upload its documents with multipart binary transfer.**
   [Source.](./examples/eSignature/eg010SendBinaryDocs.ps1)
   Binary transfer is 33% more efficient than using Base64 encoding.
1. **Use embedded sending.**
   [Source.](./examples/eSignature/eg011EmbeddedSending.ps1)
   Embeds the DocuSign web tool (NDSE) in your web app to finalize or update 
   the envelope and documents before they are sent.
1. **Embedded DocuSign web tool (NDSE).**
   [Source.](./examples/eSignature/eg012EmbeddedConsole.ps1)
1. **Use embedded signing from a template with an added document.**
   [Source.](./examples/eSignature/eg013AddDocToTemplate.ps1)
   This example sends an envelope based on a template.
   In addition to the template's document(s), the example adds an
   additional document to the envelope by using the
   [Composite Templates](https://developers.docusign.com/esign-rest-api/guides/features/templates#composite-templates)
   feature.
1. **Payments Example.**
   [Source.](./examples/eSignature/eg014CollectPayment.ps1)
   An order form, with online payment by credit card.
1. **Get the envelope tab data.**
   Retrieve the tab (field) values for all of the envelope's recipients.
   [Source.](./examples/eSignature/eg015EnvelopeTabData.ps1)
1. **Set envelope tab values.**
   The example creates an envelope and sets the initial values for its tabs (fields). Some of the tabs
   are set to be read-only, others can be updated by the recipient. The example also stores
   metadata with the envelope.
   [Source.](./examples/eSignature/eg016SetTabValues.ps1)
1. **Set template tab values.**
   The example creates an envelope using a template and sets the initial values for its tabs (fields).
   The example also stores metadata with the envelope.
   [Source.](./examples/eSignature/eg017SetTemplateTabValues.ps1)
1. **Get the envelope custom field data (metadata).**
   The example retrieves the custom metadata (custom data fields) stored with the envelope.
   [Source.](./examples/eSignature/eg018EnvelopeCustomFieldData.ps1)
1. **Requiring an Access Code for a Recipient**   
   [Source.](./examples/eSignature/eg019SigningViaEmailWithAccessCode.ps1)
   This example sends an envelope using remote (email) signing requiring the recipient to enter an access code.
1. **Send an envelope with a remote (email) signer using SMS authentication.**
   [Source.](./examples/eSignature/eg020SigningViaEmailWithSmsAuthentication.ps1)
   This example sends an envelope using remote (email) signing requiring the recipient to supply a verification code sent to them via SMS.
1. **Send an envelope with a remote (email) signer using Phone authentication.**
   [Source.](./examples/eSignature/eg021SigningViaEmailWithPhoneAuthentication.ps1)
   This example sends an envelope using remote (email) signing requiring the recipient to supply a verification code sent to them via a phone call.
1. **Send an envelope with a remote (email) signer using Knowledge-Based authentication.**
   [Source.](./examples/eSignature/eg022SigningViaEmailWithKnowledgeBasedAuthentication.ps1)
   This example sends an envelope using remote (email) signing requiring the recipient to validate their identity via Knowledge-Based authentication.
1. **Send an envelope with a remote (email) signer using Identity Verification.**
   [Source.](./examples/eSignature/eg023SigningViaEmailWithIDVAuthentication.ps1)
   This example sends an envelope using remote (email) signing requiring the recipient to validate their identity via a government issued ID.
1. **Creating a permission profile**
   [Source.](./examples/eSignature/eg024CreatingPermissionProfiles.ps1)
   This code example demonstrates how to create a permission profile using the [Create Permission Profile](https://developers.docusign.com/esign-rest-api/reference/Accounts/AccountPermissionProfiles/create) method.
1. **Setting a permission profile**
   [Source.](./examples/eSignature/eg025SettingPermissionProfiles.ps1)
   This code example demonstrates how to set a user group’s permission profile using the [Update Group](https://developers.docusign.com/esign-rest-api/reference/UserGroups/Groups/update) method. 
   You must have already created the permissions profile and the group of users.
1. **Updating individual permission settings**
   [Source.](./examples/eSignature/eg026UpdatingIndividualPermission.ps1)
   This code example demonstrates how to edit individual permission settings on a permissions profile using the [Update Permission Profile](https://developers.docusign.com/esign-rest-api/reference/Accounts/AccountPermissionProfiles/update) method.
1. **Deleting a permission profile**
   [Source.](./examples/eSignature/eg027DeletingPermissions.ps1)
   This code example demonstrates how to delete a permission profile using the [Delete Permission Profile](https://developers.docusign.com/esign-rest-api/reference/Accounts/AccountPermissionProfiles/create) method.
1. **Creating a brand**
   [Source.](./examples/eSignature/eg028CreatingABrand.ps1)
   This example creates brand profile for an account using the [Create Brand](https://developers.docusign.com/esign-rest-api/reference/Accounts/AccountBrands/create) method.
1. **Applying a brand to an envelope**
   [Source.](./examples/eSignature/eg029ApplyingBrandEnvelope.ps1)
   This code example demonstrates how to apply a brand you've created to an envelope using the [Create Envelope](https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create) method. 
   First, creates the envelope and then applies the brand to it.
   Anchor text ([AutoPlace](https://support.docusign.com/en/guides/AutoPlace-New-DocuSign-Experience)) is used to position the signing fields in the documents.
1. **Applying a brand to a template**
   [Source.](./examples/eSignature/eg030ApplyingBrandTemplate.ps1)
   This code example demonstrates how to apply a brand you've created to a template using using the [Create Envelope](https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create) method. 
   You must have already created the template and the brand.
   Anchor text ([AutoPlace](https://support.docusign.com/en/guides/AutoPlace-New-DocuSign-Experience)) is used to position the signing fields in the documents.
1. **Bulk sending envelopes to multiple recipients**
   [Source.](./examples/eSignature/eg031BulkSending.ps1)
   This code example demonstrates how to send envelopes in bulk to multiple recipients using these methods:
   [Create Bulk Send List](https://developers.docusign.com/esign-rest-api/reference/BulkEnvelopes/BulkSend/createBulkSendList), 
   [Create Bulk Send Request](https://developers.docusign.com/esign-rest-api/reference/BulkEnvelopes/BulkSend/createBulkSendRequest).
   Firstly, creates a bulk send recipients list, and then creates an envelope. 
   After that, initiates bulk envelope sending.
1. **Pausing a signature workflow Source.**
   [Source.](./examples/eSignature/eg032PauseSignatureWorkflow.ps1)
   This code example demonstrates how to create an envelope where the workflow is paused before the envelope is sent to a second recipient.
1. **Unpausing a signature workflow**
   [Source.](./examples/eSignature/eg033UnpauseSignatureWorkflow.ps1)
   This code example demonstrates how to resume an envelope workflow that has been paused
1. **Using conditional recipients**
   [Source.](./examples/eSignature/eg034UseConditionalRecipients.ps1)
   This code example demonstrates how to create an envelope where the workflow is routed to different recipients based on the value of a transaction.
1. **Request a signature by SMS delivery**
   [Source.](./examples/eSignature/eg035SMSDelivery.ps1)
   This code example demonstrates how to send a signature request via an SMS message using the [Envelopes: create](https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create) method.
 
## Rooms API 

For more information about the scopes used for obtaining authorization to use the Rooms API, see the [Required Scopes section](https://developers.docusign.com/docs/rooms-api/rooms101/auth/)

**Note:** to use the Rooms API you must also [create your DocuSign Developer Account for Rooms](https://developers.docusign.com/docs/rooms-api/rooms101/create-account). 

1. **Create room with Data.**
   [Source.](./examples/Rooms/eg001CreateRoomWithDataController.ps1)
   This example creates a new room in your DocuSign Rooms account to be used for a transaction.
1. **Create a room from a template.**
   [Source.](./examples/Rooms/eg002CreateRoomWithTemplateController.ps1)
   This example creates a new room using a template.
1. **Create room with Data.**
   [Source.](./examples/Rooms/eg003ExportDataFromRoomController.ps1))
   This example exports all the avialalble data from a specific room in your DocuSign Rooms account.
1. **Add forms to a room.**
   [Source.](./examples/Rooms/eg004AddFormsToRoomController.ps1)
   This example adds a standard real estate related form to a specific room in your DocuSign Rooms account.
1. **How to search for rooms with filters.**
   [Source.](./examples/Rooms/eg005GetRoomsWithFiltersController.ps1)
   This example searches for rooms in your DocuSign Rooms account using a specific filter. 
1. **Create an external form fillable session.**
   [Source.](./examples/Rooms/eg006CreateAnExternalFormFillSessionController.ps1)
   This example create an external form that can be filled using DocuSign for a specific room in your DocuSign Rooms account.
1. **Create a form group.**
   [Source.](./examples/Rooms/eg007CreateFormGroup.ps1)
   This example demonstrates how to create a form group for your DocuSign Rooms for Real Estate account.
1. **Grant office access to a form group.**
   [Source.](./examples/Rooms/eg008AccessFormGroup.ps1)
   This example demonstrates how to assign an office to a form group for your DocuSign Rooms for Real Estate account. 
1. **Assign a form to a form group.**
   [Source.](./examples/Rooms/eg009AssignFormGroup.ps1)
   This example demonstrates how to assign a form to a form group for your DocuSign Rooms for Real Estate account.
  
## Click API 
**Note:** To use the Click API include the <code>click_manage</code> scope. Review the [Click API 101 Auth Guide](https://developers.docusign.com/docs/click-api/click101/auth) for more details. 

1. **Create clickwraps.**
   [Source.](./examples/Click/eg001CreateClickwrap.ps1)
   Creates a clickwrap that you can embed in your website or app.
1. **Activate clickwrap.**
   [Source.](./examples/Click/eg002ActivateClickwrap.ps1)
   Activates a new clickwrap. By default, new clickwraps are inactive. You must activate your clickwrap before you can use it.
1. **Clickwrap Versioning.**
   [Source.](./examples/Click/eg003CreateNewClickwrapVersion.ps1)
   Demonstrates how to use the Click API to create a new version of a clickwrap.
1. **Retrieve clickwraps.**
   [Source.](./examples/Click/eg004GetListOfClickwraps.ps1)
   Demonstrates how to get a list of clickwraps associated with a specific DocuSign user.
1. **Get clickwrap Responses.**
   [Source.](./examples/Click/eg005GetClickwrapResponses.ps1)
   Demonstrates how to get user responses to your clickwrap agreements.


## Installation
### Prerequisites
**Note:** If you downloaded this code using [Quickstart](https://developers.docusign.com/docs/esign-rest-api/quickstart/) from the DocuSign Developer Center, skip items 1 and 2 as they were automatically performed for you.

1. A free [DocuSign developer account](https://go.docusign.com/o/sandbox/); create one if you don't already have one.
1. A DocuSign app and integration key that is configured for authentication to use either [Authorization Code Grant](https://developers.docusign.com/platform/auth/authcode/) or [JWT Grant](https://developers.docusign.com/platform/auth/jwt/).

   This [video](https://www.youtube.com/watch?v=eiRI4fe5HgM) demonstrates how to obtain an integration key.  

   To use [Authorization Code Grant](https://developers.docusign.com/platform/auth/authcode/), you will need an integration key and a secret key. See [Installation steps](#installation-steps) for details.  

   To use [JWT Grant](https://developers.docusign.com/platform/auth/jwt/), you will need an integration key, an RSA key pair, and the API Username GUID of the impersonated user. See [Configure the launcher to use JWT Grant](#configure-the-launcher-to-use-jwt-grant) for details.  

   For both authentication flows:  
   
   If you use this launcher on your own workstation, the integration key must include a redirect URI of http://localhost:8080/authorization-code/callback.  

   If you host this launcher on a remote web server, set your redirect URI as:  
   
   {base_url}/authorization-code/callback   
   
   where {base_url} is the URL for the web app.  
   
1. PowerShell 5 or later


### Installation steps
**Note:** If you downloaded this code using [Quickstart](https://developers.docusign.com/docs/esign-rest-api/quickstart/) from the DocuSign Developer Center, skip step 3 as it was automatically performed for you.

1. Extract the Quickstart ZIP file or download or clone the code-examples-powershell repository.
1. In File Explorer, open your Quickstart folder or your code-examples-powershell folder.
1. To configure the launcher for [Authorization Code Grant](https://developers.docusign.com/platform/auth/authcode/) authentication, create a copy of the file config/settings.example.json and save the copy as config/settings.json.
   1. Add your integration key. On the [Apps and Keys](https://admindemo.docusign.com/authenticate?goTo=apiIntegratorKey) page, under **Apps and Integration Keys**, choose the app to use, then select **Actions** > **Edit**. Under **General Info**, copy the **Integration Key** GUID and save it in settings.json as your `INTEGRATION_KEY_AUTH_CODE`.
   1. Generate a secret key, if you don’t already have one. Under **Authentication**, select **+ ADD SECRET KEY**. Copy the secret key and save it in settings.json as your `SECRET_KEY`.
   1. Add the launcher’s redirect URI. Under **Additional settings**, select **+ ADD URI**, and set a redirect URI of http://localhost:8080/authorization-code/callback. Select **SAVE**.   
   1. Set a name and email for the signer. In settings.json, save an email address as `SIGNER_EMAIL` and a name as `SIGNER_NAME`.  
**Note:** Protect your personal information. Please make sure that settings.json will not be stored in your source code repository.
1. Run the launcher. In the root folder, right-click the **launcher** file and select **Run with PowerShell** > **Open**; then select an API when prompted in Windows PowerShell.
1. Select **Authorization Code Grant** when authenticating your account.
1. Select your desired code example.


### Configure the launcher to use JWT Grant
1. To configure the launcher for [JWT Grant](https://developers.docusign.com/platform/auth/jwt/) authentication, create a copy of the file config/settings.example.json and save the copy as config/settings.json.
   1. Add your API Username. On the [Apps and Keys](https://admindemo.docusign.com/authenticate?goTo=apiIntegratorKey) page, under **My Account Information**, copy the **API Username** and save it in settings.json as your `IMPERSONATION_USER_GUID`.
   1. Add your integration key. On the [Apps and Keys](https://admindemo.docusign.com/authenticate?goTo=apiIntegratorKey) page, under **Apps and Integration Keys**, choose the app to use, then select **Actions** > **Edit**. Under **General Info**, copy the **Integration Key** GUID and save it in settings.json as your `INTEGRATION_KEY_JWT`.
   1. Generate an RSA key pair, if you don’t already have one. Under **Authentication**, select **+ GENERATE RSA**. Copy the private key and save it in a new file named config/private.key.
   1. Add the launcher’s redirect URI. Under **Additional settings**, select **+ ADD URI**, and set a redirect URI of http://localhost:8080/authorization-code/callback. Select **SAVE**.   
   1. Set a name and email for the signer. In settings.json, save an email address as `SIGNER_EMAIL` and a name as `SIGNER_NAME`.  
**Note:** Protect your personal information. Please make sure that settings.json will not be stored in your source code repository.
1. Run the launcher. In the root folder, right-click the **launcher** file and select **Run with PowerShell** > **Open**; then select an API when prompted in Windows PowerShell.
1. Select **JSON Web Token** when authenticating your account.
1. Select your desired code example.


### Payments code example
To use the payments code example, create a test payments gateway on the [**Payments**](https://admindemo.docusign.com/authenticate?goTo=payments) page in your developer account. See [PAYMENTS_INSTALLATION](./PAYMENTS_INSTALLATION.md) for details.

Once you've created a payment gateway, save the **Gateway Account ID** GUID in settings.json.


## License and additional information

### License
This repository uses the MIT License. See the LICENSE file for more information.

### Pull Requests
Pull requests are welcomed. Pull requests will only be considered if their content
uses the MIT License.
