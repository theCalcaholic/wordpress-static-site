# Prerequisites

This installation guide works and is tested on Linux. It might also work on Mac and partially on Windows (with a bash compatible shell installed, e.g. WSL or MingW64), but I haven't tested that. If it's not fully working out of the box, the guide can probably still serve as an orientation to setting things up manually on those operating systems, though.

You will need to have installed either podman or docker on your system and your user needs to be allowed to use either container engine in rootfull mode.

If you want to setup your site publicly with letsencrypt certificates, you will need 4 separate domains (or subdomains) pointing to your servers IP address: one for your live site, one for the comments system, one for the analytics platform and one for the admin section (wordpress).

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

Navigate to https://matomo.<your-domain\> or https://\<your-matomo-domain\> (depending on your choices in the init script) and complete the installation and initial user creation. You will have to login with your basic auth credentials before getting access to the site.
Use the prefilled values in the database configuration step.
![image](https://github.com/user-attachments/assets/b7085023-cf95-4fa3-b508-903f6b206111)

In the step "Set up a Website", use the base domain of your site (i.e. without admin.), e.g.:
![image](https://github.com/user-attachments/assets/642dd4b2-f54f-4071-bbf0-7ebf5c1831b4)

### 4. Setup Comentario

*NOTE: If using locally signed certificates. those won't be trusted by Firefox atm. Please use another browser*

Navigate to https://comments.<your-domain\> or https://\<your-comments-domain\> (depending on your choices in the init script), sign up and then login with a new user.
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

Navigate to https://admin.<your-domain\> or https://\<your-admin-domain\> (depending on your choices in the init script) and complete the Wordpress installation and initial user creation. You will have to login with your basic auth credentials before getting access to the site.
Then login to wordpress.

From now on, you will be able to login to wordpress at https://admin.<your-domain\>/wp-login.php (https://\<your-admin-domain\>/wp-login.php respectively).

#### Setup Wordpress static site generation

Head over to plugins, then install and activate the [Staatic][staatic] plugin.

Go to Settings -> Permalinks and choose any option but "plain" (articles need to have unique paths instead of query parameters).

Now go to the Staatic -> Settings and change the following settings:

- In the *Build* tab, add *additional paths* (e.g. image/asset directories from your theme), as needed.
- In the *Deployment* tab, change the target directory to `/staatic-out` (deployment method should stay "local directory").
  ![image](https://github.com/user-attachments/assets/c7e613fb-a761-40cd-b861-7b599e31f1e6)
- In the *Advanced* tab, check the box at *Downgrade HTTPS to HTTP while crawling site*.
  ![image](https://github.com/user-attachments/assets/95162bbe-a6b1-410c-80ae-a4aab0bddfa1)

Finally, go to Staatic -> Publications and hit "Publish now". This will trigger a publish process and once that is complete, you should find your static wordpress site at https://\<your-base-domain\>.

[staatic]: https://wordpress.org/plugins/staatic/


### 6. Connect Comentario

Open Comentario at https://comments.<your-domain\> (https://\<your-comments-domain\>) and login. Now go to Domains and select the domain of your blog (create it if it does not exist yet).
There you will find an HTML snippet, that you can customize and copy. Store this snippet for later.

*Note: Following, you will insert the comments HTML snippet directly into the source code of your theme. There may be better ways to do this, e.g. if your theme has special functionality for inserting HTML on each page/post or with another plugin. Suggestions welcome!*

Now go to wordpress (https://admin.<your-domain\> or https://\<your-admin-domain\>) and login. Got to Tools -> Theme File Editor. Find the files that are responsible for rendering single pages and posts (in the case of the default twenty wenty-five theme, for example, those are templates/single.html and template/page.html. Insert the HTML snippet copied from Comentario there.

Alternatively, check if your theme uses a pattern for comments. For example in the case of the twenty twenty-five theme, this looks like this (inside templates/single.html):

```html
<!-- wp:pattern {"slug":"twentytwentyfive/comments"} /-->
```
If you theme uses a pattern, it's probably a better idea to insert the HTML snippet in the respective pattern - you will find it under patterns/\<pattern-name\> in the theme file editor. For example, I would change the pattern like this (with my blog domain being https://my.blog and the twenty twenty-five theme):

<details>
  <summary>patterns/comments.php</summary>
  
```diff
<?php
/**
 * Title: Comments
 * Slug: twentytwentyfive/comments
 * Description: Comments area with comments list, pagination, and comment form.
 * Categories: text
 * Block Types: core/comments
 *
 * @package WordPress
 * @subpackage Twenty_Twenty_Five
 * @since Twenty Twenty-Five 1.0
 */

?>
<!-- wp:comments {"className":"wp-block-comments-query-loop","style":{"spacing":{"margin":{"top":"var:preset|spacing|70","bottom":"var:preset|spacing|70"}}}} -->
<div class="wp-block-comments wp-block-comments-query-loop" style="margin-top:var(--wp--preset--spacing--70);margin-bottom:var(--wp--preset--spacing--70)">
	<!-- wp:heading {"fontSize":"x-large"} -->
	<h2 class="wp-block-heading has-x-large-font-size"><?php esc_html_e( 'Comments', 'twentytwentyfive' ); ?></h2>
	<!-- /wp:heading -->
- 	<!-- wp:comments-title {"level":3,"fontSize":"large"} /-->
- 	<!-- wp:comment-template -->
- 	<!-- wp:group {"style":{"spacing":{"margin":{"top":"0","bottom":"var:preset|spacing|50"}}}} -->
- 	<div class="wp-block-group" style="margin-top:0;margin-bottom:var(--wp--preset--spacing--50)">
- 		<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap","verticalAlignment":"top"}} -->
- 		<div class="wp-block-group">
- 			<!-- wp:avatar {"size":50} /-->
- 			<!-- wp:group -->
- 			<div class="wp-block-group">
- 				<!-- wp:comment-date /-->
- 				<!-- wp:comment-author-name /-->
- 				<!-- wp:comment-content /-->
- 				<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap"}} -->
- 				<div class="wp-block-group">
- 					<!-- wp:comment-edit-link /-->
- 					<!-- wp:comment-reply-link /-->
- 				</div>
- 				<!-- /wp:group -->
- 			</div>
- 			<!-- /wp:group -->
- 		</div>
- 		<!-- /wp:group -->
- 	</div>
- 	<!-- /wp:group -->
- 	<!-- /wp:comment-template -->
- 
- 	<!-- wp:comments-pagination {"layout":{"type":"flex","justifyContent":"space-between"}} -->
- 	<!-- wp:comments-pagination-previous /-->
- 	<!-- wp:comments-pagination-next /-->
- 	<!-- /wp:comments-pagination -->
- 
- 	<!-- wp:post-comments-form /-->
+   <script defer src="https://comments.my.blog/comentario.js"></script>
+   <comentario-comments theme="light"></comentario-comments>
</div>
<!-- /wp:comments -->
```
</details>

Afterwards, publish your site again with Staatic (see [section 5: setup Wordpress](#5-setup-wordpress)) and you should see Comentario comments under your posts and pages.
![image](https://github.com/user-attachments/assets/833de6ad-40a6-4b9f-a9c1-094c79a95fec)


### 7. Connect Matomo

*Note: This part only works reliable if your domains are publicly reachable. If you are testing things locally, Matomo might fail to connect.*

First of all open matomo at https://matomo.<your-domain\> (https://\<your-matomo-domain\> respectively), login and go to Administration (the cog wheel at the top right) -> Personal -> Security. On this page, scroll down to the "Auth Tokens" section and click on "Create new Token".
![image](https://github.com/user-attachments/assets/c30077de-2ea8-475b-bcea-7e4c70b0c942)
After creating the token, copy it and store it for later.

Now head over to Wordpress (https://admin.<your-domain\> or https://\<your-admin-domain\>) and login.
Install and activate the Wordpress plugin [Connect Matomo (wp-piwik)](https://wordpress.org/plugins/wp-piwik/). Then go to Settings -> Connect Matomo and configure it as follows:

Matomo Mode: `Self-hosted (HTTP API, default)`
Matomo URL: `https://matomo.<your-domain>` (or `https://<your-matomo-domain>`)
Auth token: enter the auth token copied in Matomo previously
Auto config: checked

![image](https://github.com/user-attachments/assets/c6a2ef41-d719-467b-8d14-45088ec7325d)

No go to the "Enable Tracking" tab and configure Matomo to your liking.

Again, don't forget to regenerate your page with Staatic to see your changes in the live site.
