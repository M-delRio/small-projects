app method's

`refresh`
- calls api.getAllContacts();
- get request is made to retrieve all contacts and save value as a property of `app`

`displayContacts`
- provides context to the `contacts` template and injects the resulting html in the
displayContacts Section
- if a collection argument is passed to the method only the selected contacts are
provided as context to the template

`showForm`
- animation that includes hiding the nav and either the existing contacts or the no existing contacts display and showing the add contact form

`hideForm`
- animation that includes sliding(showing) the nav and either the existing contacts or the no existing contacts display and hiding the add contact form

`addContact`
- uses data returned by collectContactData and coerces the object to a string (json string) and sends this string to the api addContact

`collectContactData`
- collects values from forms and returns an object with the these values including the tags values concatenated as a string

`displayEdit`
- save id of element as app property
- populate form with current contacts values as contact
- show form

`deleteContact`
- save id of element as app property
- call `displayDeletePrompt`

`displayDeletePrompt`
- display the modal and the overlay  

`hideDeletePrompt`
- hide the modal and the overlay

`sendDelete`
- proceed with delete request
- call api `deleteContact` method, sending the id as the argument

`displaySearchContacts`
- filters the current contacts according to the search query and passes the collection
of contacts to the `displayContacts` method

`displayByTag`
- filters the existing collection of contacts and passes the return value to the `displayContacts` method

`isFormValid`
- check if any of the non-checkbox input elements of the form fail to
pass constraint validation, if okay continue submitting form, call 
`toggleInvalidHighlight` with argument to reflect wheter the highlight
class should be added or remove

`toggleInvalidHighlight`
- add or remove class of input to reflect whether the entry is valid



