# zammad-microk8s-deploy

This is a script to deploy zammad using microk8s. You must have to give as argument the port that you want to expose for the application, and a second argument to indicate the port for pgAdmin

# pgAdmin

To connect with zammad database use the following data

Postgres port: 5432
database name: zammad_production
username: zammad
password: zammad

# Add new ticket state


To add new ticket statuses it is necessary to first execute the following:

microk8s kubectl exec -it zammad-0 -n zammad /bin/bash


then inside the console of the pod execute:

rails console


After that, follow the steps described in https://docs.zammad.org/en/latest/admin/console/working-on-tickets.html#add-new-ticket-state to add a new ticket status.


To make the added ticket statuses visible, execute the following inside the console
of rails

attribute = ObjectManager::Attribute.get(
     object: 'Ticket',
     name: 'state_id',
   )

attribute.data_option[:filter] = Ticket::State.by_category(:viewable).pluck(:id)
attribute.screens[:create_middle]['ticket.agent'][:filter] = Ticket::State.by_category(:viewable_agent_new).pluck(:id)
attribute.screens[:create_middle]['ticket.customer'][:filter] = Ticket::State.by_category(:viewable_customer_new).pluck(:id)
attribute.screens[:edit]['ticket.agent'][:filter] = Ticket::State.by_category(:viewable_agent_edit).pluck(:id)
attribute.screens[:edit]['ticket.customer'][:filter] = Ticket::State.by_category(:viewable_customer_edit).pluck(:id)
attribute.save!