# Installation

### 1. Clone this repository and run the interactive init script

```bash
git clone https://github.com/theCalcaholic/wordpress-static-site
cd wordpress-static-site
bash ./init.sh
```

Various config files will be generated based on your choices.

### 2. Start the containers

*NOTE: If you want to trusted certificates (issued by Letsencrypt), your domain's DNS should be configured to point at your server's IP address at this point.*

Run:

<details>
  <summary>podman</summary>
    
  ```bash
  podman compose up 
  ```

</details>

<details>
  <summary>docker</summary>
  
  ```bash
  docker compose up 
  ```

</details>

### 3. Setup Matomo

*NOTE: If using locally signed certificates. those won't be trusted by Firefox atm. Please use another browser*

Navigate to https://matomo.<your-domain> or https://<your-matomo-domain> (depending on your choices in the init script) and complete the installation and initial user creation. You will have to login with your basic auth credentials before getting access to the site.
Use the prefilled values in the database configuration step.
![image](https://github.com/user-attachments/assets/b7085023-cf95-4fa3-b508-903f6b206111)

In the step "Set up a Website", use the base domain of your site (i.e. without admin.), e.g.:
![image](https://github.com/user-attachments/assets/642dd4b2-f54f-4071-bbf0-7ebf5c1831b4)

### 4. Setup Comentario

*NOTE: If using locally signed certificates. those won't be trusted by Firefox atm. Please use another browser*

Navigate to https://comments.<your-domain> or https://<your-comments-domain> (depending on your choices in the init script), sign up and then login with a new user.
Now head over to "Domains" and create a new domain using the base domain of your site, e.g.:
![image](https://github.com/user-attachments/assets/9341f557-a3c1-4d84-8570-b80801dfa009)

Copy the html snippet presented after the creation of the domain and save it for later.
![image](https://github.com/user-attachments/assets/6d0e15b5-8d04-46aa-8e60-9f34713c873c)


### 5. Setup Wordpress

*NOTE: If using locally signed certificates. those won't be trusted by Firefox atm. Please use another browser*

First, you need to make the volume for your static files writable by wordpress. To do that, run the following command (inside the repo directory):

<details>
  <summary>podman</summary>
  
```bash
podman compose exec wordpress chown www-data: /staatic-out
```
</details>
<details>
  <summary>docker</summary>
  
```bash
docker compose exec wordpress chown www-data: /staatic-out
```
</details>

Navigate to https://admin.<your-domain> or https://<your-admin-domain> (depending on your choices in the init script) and complete the Wordpress installation and initial user creation. You will have to login with your basic auth credentials before getting access to the site.
Then login to wordpress.

From now on, you will be able to login to wordpress at https://admin.<your-domain>/wp-login.php (https://<your-admin-domain>/wp-login.php respectively).

#### Setup Wordpress static site generation

Head over to plugins, then install and activate the [Staatic][staatic] plugin.

Go to Settings -> Permalinks and choose any option but "plain" (articles need to have unique paths instead of query parameters).

Now go to the Staatic -> Settings and change the following settings:

- In the *Build* tab, add *additional paths* (e.g. image/asset directories from your theme), as needed.
- In the *Deployment* tab, change the target directory to `/staatic-out` (deployment method should stay "local directory").
  ![image](https://github.com/user-attachments/assets/c7e613fb-a761-40cd-b861-7b599e31f1e6)
- In the *Advanced* tab, check the box at *Downgrade HTTPS to HTTP while crawling site*.
  ![image](https://github.com/user-attachments/assets/95162bbe-a6b1-410c-80ae-a4aab0bddfa1)

Finally, go to Staatic -> Publications and hit "Publish now". This will trigger a publish process and once that is complete, you should find your static wordpress site at https://<your-base-domain>.

[staatic]: https://wordpress.org/plugins/staatic/
