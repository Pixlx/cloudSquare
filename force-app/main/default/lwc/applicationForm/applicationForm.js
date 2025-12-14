import { LightningElement, track} from 'lwc';
//import your apex method
import submitApplication from '@salesforce/apex/ApplicationFormController.submitApplication';

export default class ApplicationForm extends LightningElement {
    @track formData = {
        firstName : '',
        lastName : '',
        company : '',
        email : '',
        phone : '',
        federalTaxId : '',
        annualAccountRevenue : 0.00
    }
    
    // 1. New Property to hold notification state
    @track notification = {
        message: '',
        variant: '', // 'success' or 'error'
        isVisible: false
    };

    @track buttonClicked = false;
    @track isSpinnerActive = false;

    handleChange(event) {
        this.formData[event.target.name] = event.target.value;
    }

    // 2. Helper function to show notification
    showNotification(message, variant) {
        this.notification.message = message;
        this.notification.variant = variant;
        this.notification.isVisible = true;

        // Optionally, auto-hide the notification after 5 seconds
        window.clearTimeout(this.timeoutId);
        this.timeoutId = window.setTimeout(() => {
            this.notification.isVisible = false;
        }, 5000);
    }
    
    // 3. Update handleClick to use the new notification method
    handleClick() {

        //format the form data as the Application DTO wrapper class.

        const applicationData = {

            companyName : this.formData.company,
            federalTaxId : this.formData.federalTaxId,
            annualRevenue : Number(this.formData.annualAccountRevenue),
            contact : {
                firstName : this.formData.firstName,
                lastName : this.formData.lastName,
                email : this.formData.email,
                phone : this.formData.phone
            }
        }

        this.buttonClicked = true;
        this.isSpinnerActive = true;

        submitApplication({input : applicationData})
            .then(result => {
                
                this.isSpinnerActive = false;
                this.showNotification('Successfully created ' + result.recordType + 'Record Id: ' + result.recordId, 'success');
                
            })
            .catch(error => {
                this.showNotification('Something Went Wrong ' + JSON.stringify(error.body ? error.body.message : error), 'error');
            });
    }

}