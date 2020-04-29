$(() => {
  let app;
  let api;
  let templates = {};

  $("script[type='text/x-handlebars-template']").each(function() {
    let $template = $(this);
    templates[$template.attr("id")] = Handlebars.compile($template.html());
  });

  {
    app = { 
      $main: $('main'), 
      $confirmDelete: $('#delete_modal'),
      $mainForm: $('#main_form_section'),
      $displayContacts: $('#display_contacts'),
      $noContactsDisplay: $('#no_contacts_display'),
      $nav: $('nav'),
      $tagFilterForm: $('#tag_filter'),

      contacts: undefined,

      selectedId: undefined,

      displayContacts: function(_, selectContacts = this.contacts) {
        this.hideForm();     
        let contactsHtml = '';        

        if(this.contacts.length > 0) {
          this.$noContactsDisplay.hide();
          contactsHtml = templates.contacts({ contacts: selectContacts });
        } 
        
        this.$displayContacts.html(contactsHtml);
      },

      displaySearchContacts: function(event) {       
        let searchQuery = event.target.value;        

        selectContacts = 
          this.contacts.filter(contact => {
            return contact['full_name'].includes(searchQuery);
          });

        this.displayContacts(null, selectContacts);
      },

      displayByTag: function(event) {
        let formData = $('#tag_filter').serializeArray();      
        let selectedTagNames = formData.map(selectedTag => selectedTag.name); 

        if (formData.length === 0) {
          this.displayContacts();
          return;
        }
        
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
        };

        addContactContext['button_name'] = "add";

        this.populateForm(addContactContext);
        this.showForm();
      },

      displayEditContact: function(event) {
        this.updateId(event);

        let tagNames = ['work', 'friend', 'business'];
        let tagContext = {
          work: '',
          friend: '',
          business: '',
        };
        
        let editContactContext = 
          this.contacts.filter(contact => {
            return contact.id === +this.selectedId;
          })[0];        

        editContactContext.title = "Edit Contact";
        editContactContext.button_name = "edit";

        tagNames.forEach(tagName => {
          if (editContactContext.tags.includes(tagName)) {
            tagContext[tagName] = 'checked';
          }
        });

        editContactContext.tags = tagContext;

        this.populateForm(editContactContext);
        this.showForm();
      },

      showForm: function(event) { 
        this.$main.append(this.$mainForm);
     
        this.$mainForm.slideDown();

        $('#no_contacts_display').hide();
        this.$displayContacts.slideUp();      
        this.$nav.slideUp();
      },

      hideForm: function(event) {      
        this.$main.prepend(this.$mainForm);

        if(this.contacts.length === 0) {
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

      addContact: function(event) {
        event.preventDefault();
        let data = this.collectContactData();

        if (this.isFormValid() === true) {
          api.addContact(JSON.stringify(data));
        }        
      },

      editContact: function(event) {
        event.preventDefault();

        data = this.collectContactData();
        api.editContact(JSON.stringify(data), this.selectedId);
      },

      updateId: function(event) {
        let $li = $(event.target).parent();
        this.selectedId = $li.find('dl').attr('data-id');
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

      sendDelete: function(event) {
        this.hideDeletePrompt();

        let data = {
          id: +this.selectedId,
        };
        
        api.deleteContact(data);
      },

      refresh: function() {       
        api.getAllContacts();
      },

      bindEvents: function() {
        this.$main.on('click', 'button.add', this.displayAddContact.bind(this));    
        this.$mainForm.on('click', `#cancel`, this.displayContacts.bind(this));    
        this.$mainForm.on('click', 'button[name=add]', this.addContact.bind(this));    
        this.$mainForm.on('click', 'button[name=edit]', this.editContact.bind(this));    
        this.$displayContacts.on('click', 'li button#edit', this.displayEditContact.bind(this));    
        this.$displayContacts.on('click', 'li button#delete', this.deleteContact.bind(this));    
        this.$confirmDelete.on('click', 'button:last-of-type', this.hideDeletePrompt.bind(this));    
        this.$confirmDelete.on('click', 'button:first-of-type', this.sendDelete.bind(this));            
        this.$nav.on('input', '> input', this.displaySearchContacts.bind(this));    
        this.$tagFilterForm.on('input', 'input', this.displayByTag.bind(this));      
      },

      init: function() {
        this.bindEvents();
        this.refresh();
      }
    };

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
            app.contacts = data;
            app.displayContacts();           
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
            app.refresh();
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
            app.refresh();           
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
            app.refresh();
          },
        });
      }, 
    };
  }

  app.init();
});