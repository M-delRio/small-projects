$(() => {
  let contacts;
  let ui;
  let app;
  let api;
  let templates = {};

  $("script[type='text/x-handlebars-template']").each(function() {
    let $template = $(this);
    templates[$template.attr("id")] = Handlebars.compile($template.html());
  });

  {
    contacts = {
      contacts: undefined,

      selectedId: undefined,

      selectedContactData: function() {
        return this.contacts.filter(contact => contact.id === +contacts.selectedId )[0];
      },

      tagContext: function() {
        let tagNames = ['work', 'friend', 'business'];
        let tagContext = {
          work: '',
          friend: '',
          business: '',
        };       

        tagNames.forEach(tagName => {
          if (this.selectedContactData().tags.includes(tagName)) {
            tagContext[tagName] = 'checked';
          }          
        });

        return tagContext;
      },

      searchResults: function(query) {
        return this.contacts.filter(contact => contact['full_name'].includes(query));
      },

      filterByTag: function(selectedTagNames) {
        let taggedContacts = this.contacts.filter(contact => contact.tags);

        let selectContacts =
          taggedContacts.filter(contact => {
            let match = false;
            
            selectedTagNames.forEach(tag => {                    
              if (contact.tags && contact.tags.includes(tag) === true) {
                match = true;
              }
            });
            return match;
          });

        return selectContacts;
      },
    };

    ui = { 
      $main: $('main'), 
      $confirmDelete: $('#delete_modal'),
      $mainForm: $('#main_form_section'),
      $displayContacts: $('#display_contacts'),
      $noContactsDisplay: $('#no_contacts_display'),
      $nav: $('nav'),
      $tagFilterForm: $('#tag_filter'),

      displayContacts: function(_, selectContacts = contacts.contacts) {
        this.hideForm();   
        $noContactsDisplay.hide();  
        let contactsHtml = '';        

        if(contacts.contacts.length > 0) {
          this.$noContactsDisplay.hide();
          contactsHtml = templates.contacts({ contacts: selectContacts });
        } 

        // this.$noContactsDisplay.slideDown('slow');
        
        this.$displayContacts.html(contactsHtml);
      },

      displaySearchContacts: function(event) {       
        let searchQuery = event.target.value;        
        let selectContacts = contacts.searchResults(searchQuery);

        this.displayContacts(null, selectContacts);
      },

      displayByTag: function(event) {
        let formData = $('#tag_filter').serializeArray();      
        let selectedTagNames = formData.map(selectedTag => selectedTag.name); 

        if (formData.length === 0) {
          this.displayContacts();
          return;
        }
        
        let selectContacts = contacts.filterByTag(selectedTagNames);

        this.displayContacts(null, selectContacts);
      },

      populateForm: function(context) {
        let formHtml = templates['contact_form'](context);        
        this.$mainForm.html(formHtml);
      },

      displayAddContact: function() {
        $('#no_contacts_display').hide();

        let addContactContext = {
          title: 'Create Contact', 
          button_name: 'add'       
        };

        this.populateForm(addContactContext);
        this.showForm();
      },

      displayEditContact: function(event) {
        this.updateId(event);
              
        let editContactContext = contacts.selectedContactData();

        editContactContext.title = "Edit Contact";
        editContactContext.button_name = "edit";

        editContactContext.tags = contacts.tagContext();

        this.populateForm(editContactContext);
        this.showForm();
      },

      showForm: function(event) { 
        this.$main.append(this.$mainForm);
        this.$mainForm.slideDown('slow');

        $('#no_contacts_display').hide();
        this.$displayContacts.slideUp('slow');      
        this.$nav.slideUp();
      },

      hideForm: function(event) {      
        this.$main.prepend(this.$mainForm);

        if(contacts.contacts.length === 0) {
          $('#no_contacts_display').slideDown();
        } else {
          this.$displayContacts.slideDown();
        }

        this.$nav.slideDown();
        this.$mainForm.slideUp();
      }, 

      collectContactData: function() {
        let data = {};
        let $form = this.$mainForm.find('form');
        let $tags = $form.find('fieldset:last-of-type input');
        let tags = [];

        $form.find('fieldset:first-of-type input').each((idx, field) => {
          data[field.name] = field.value;
        });      

        let $selectedTags = 
          $tags.filter((idx, tag) => tag.checked === true);
        
        $selectedTags.each((idx, tag) => tags.push(tag.name));
        
        data.tags = tags.join();
        
        return data;
      },

      toggleInvalidHighlight: function(inputElement, action) {
        let label = $(inputElement).parent()[0];
        let invalidP = $(label).next()[0];

        if (action === 'add') {
          inputElement.classList.add('invalid_border');
          label.classList.add('highlight_text');
          invalidP.classList.remove('hidden');
        } else {
          inputElement.classList.remove('invalid_border');
          label.classList.remove('highlight_text');
          invalidP.classList.add('hidden');
        }        
      },

      isFormValid: function() {
        let $inputs = this.$mainForm.find('fieldset:first-of-type input');
        let formValidity = true;

        $inputs.each((idx, input) => {         
          if (input.checkValidity() === false) {
            this.toggleInvalidHighlight(input, 'add');
            formValidity = false;
          } else {
            this.toggleInvalidHighlight(input, 'remove');
          }
        });
        return formValidity;        
      },

      updateId: function(event) {
        let $li = $(event.target).parent();
        contacts.selectedId = $li.find('dl').attr('data-id');
      },

      displayDeletePrompt: function() {
        $('#overlay').show();
        this.$confirmDelete.show();
      },

      hideDeletePrompt: function() {
        $('#overlay').hide();
        this.$confirmDelete.hide();
      },

      deleteContact: function(event) {
        this.updateId(event);
        this.displayDeletePrompt();
      },

      refresh: function() {       
        api.getAllContacts();
      },

      processAddContact: function(event) {
        event.preventDefault();
        let data = this.collectContactData();

        if (this.isFormValid() === true) {
          app.addContact(data)
        }   
      },

      processEditContact: function(event) {
        event.preventDefault();
        let data = this.collectContactData();

        if (this.isFormValid() === true) {
          app.editContact(data)
        }  
      },

      confirmDelete: function(event) {
        this.hideDeletePrompt();

        let data = {
          id: +contacts.selectedId,
        };

        api.deleteContact(data);
      },

      bindEvents: function() {
        this.$mainForm.on('click', `#cancel`, this.displayContacts.bind(this));    
        this.$main.on('click', 'button.add', this.displayAddContact.bind(this));    
        this.$mainForm.on('click', 'button[name=add]', this.processAddContact.bind(this));          
        this.$displayContacts.on('click', 'li button#edit', this.displayEditContact.bind(this));    
        this.$mainForm.on('click', 'button[name=edit]', this.processEditContact.bind(this));    
        this.$displayContacts.on('click', 'li button#delete', this.deleteContact.bind(this));    
        this.$confirmDelete.on('click', 'button:last-of-type', this.hideDeletePrompt.bind(this));    
        this.$confirmDelete.on('click', 'button:first-of-type', this.confirmDelete.bind(this));            
        this.$nav.on('input', '> input', this.displaySearchContacts.bind(this));    
        this.$tagFilterForm.on('input', this.displayByTag.bind(this));      
      },

      init: function() {
        this.bindEvents();
        this.refresh();
      }
    };

    app = {
      addContact: function(data) {
        api.addContact(JSON.stringify(data));
      },

      editContact: function(data) {     
        api.editContact(JSON.stringify(data), contacts.selectedId);
      },

      sendDelete: function(data) {       
        api.deleteContact(data);
      },
    }

    api = {
      url: 'http://localhost:3000/api/contacts/',

      getAllContacts: function(data) {        
        $.ajax({
          method: 'GET',
          url: this.url,
          dataType: 'json',
          headers: {
            'Content-Type': `application/json`
          },
          success: (data, status) => { 
            contacts.contacts = data;
            ui.displayContacts();           
          },
        });
      }, 

      addContact: function(data) {        
        $.ajax({
          method: 'POST',
          url: this.url,
          data: data,
          dataType: 'json',
          headers: {
            'Content-Type': `application/json`
          },
          success: (data, status) => {
            ui.refresh();
          },
        });
      }, 

      editContact: function(data, id) {
        $.ajax({
          method: 'PUT',
          url: this.url + id,
          data: data,
          dataType: 'json',
          headers: {
            'Content-Type': `application/json`
          },
          success: (data, status) => {
            ui.refresh();           
          },

        });
      },

      deleteContact: function(data) {                        
        $.ajax({
          method: 'DELETE',
          url: this.url + `${data.id}`,
          data: JSON.stringify(data),
          headers: {
            'Content-Type': `application/json`
          },
          success: (data, status) => {
            ui.refresh();
          },
        });
      }, 
    };
  }

  ui.init();
});