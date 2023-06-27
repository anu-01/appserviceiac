using 'main.bicep'

param kvname = 'kvappserviceiac'
// param sqlAdministratorLogin = 'sqluser'
param sqlAdministratorLoginPassword = 'password1#'
param customerPlans = [
            {
                name: 'plan1'
                sku: 'F1'
                capacity: '1'
                customers: [
                    {
                        name: 'customer1'
                        logo: ''
                        splash: ''
                        start: 'CreateDashboard'
                        productHubUrl: 'https://www.oneadvanced.com/'
                        volumes: [{
                          documents: [{
                            icon: ''
                            path: 'App_Data\\Documents'
                          }]
                        }]
                        links: [{
                          name: 'Terms of Use'
                          url: 'https://www.oneadvanced.com/'
                        }
                        {
                          name: 'Privacy Policy'
                          url: 'https://www.oneadvanced.com/'
                        }]
                        dbSku: {
                            name: 'Basic'
                            tier: 'Basic'
                            family: ''
                            capacity: '5'
                            }
            
                    }
                    {
                        name: 'customer2'
                        logo: ''
                        splash: ''
                        start: 'CreateDashboard'
                        productHubUrl: 'https://www.oneadvanced.com/'
                        volumes: [{
                          documents: [{
                            icon: ''
                            path: 'App_Data\\Documents'
                          }]
                        }]
                        links: [{
                          name: 'Terms of Use'
                          url: 'https://www.oneadvanced.com/'
                        }
                        {
                          name: 'Privacy Policy'
                          url: 'https://www.oneadvanced.com/'
                        }]
                        dbSku: {
                                name: 'Basic'
                                tier: 'Basic'
                                family: ''
                                capacity: '5'
                            }
                    }
                    {
                        name: 'customer4'
                        logo: ''
                        splash: ''
                        start: 'CreateDashboard'
                        productHubUrl: 'https://www.oneadvanced.com/'
                        volumes: [{
                          documents: [{
                            icon: ''
                            path: 'App_Data\\Documents'
                          }]
                        }]
                        links: [{
                          name: 'Terms of Use'
                          url: 'https://www.oneadvanced.com/'
                        }
                        {
                          name: 'Privacy Policy'
                          url: 'https://www.oneadvanced.com/'
                        }]
                        dbSku: {
                                name: 'Basic'
                                tier: 'Basic'
                                family: ''
                                capacity: '5'
                            }
                    }
                ]
            }
            {                
                name: 'plan2'
                sku: 'F1'
                capacity: '1'
                customers: [                    
                    {
                        name: 'customer3'
                        logo: ''
                        splash: ''
                        start: 'CreateDashboard'
                        productHubUrl: 'https://www.oneadvanced.com/'
                        volumes: [{
                          documents: [{
                            icon: ''
                            path: 'App_Data\\Documents'
                          }]
                        }]
                        links: [{
                          name: 'Terms of Use'
                          url: 'https://www.oneadvanced.com/'
                        }
                        {
                          name: 'Privacy Policy'
                          url: 'https://www.oneadvanced.com/'
                        }]
                        dbSku: {
                                name: 'Basic'
                                tier: 'Basic'
                                family: ''
                                capacity: '5'
                            }
                    }
                ]
            }
        ]

