# Logging-on

To connect to the Aire platform, the steps vary depending on whether you are on the wired campus network or offsite/using Eduroam. If you are offsite, you must connect through the University's SSH gateway or use the University VPN. However, if you are on the campus network, no additional steps are required.

:::{note}
Connecting via Eduroam or from the NHS network in St James's University Hospital are considered off-site connections. 
:::

You can connect to Aire and log in using SSH (Secure Shell) from within the University network.
Please see the following Knowledge Base articles for more information:

+ <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018286" target="_blank">KB0018286 - How do I connect to Aire from Windows (on-campus wired or off-campus/eduroam)?</a>
+ <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018275" target="_blank">KB0018275 - How do I log in to Aire on Linux or Mac OS from on Campus?</a>
+ <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018284" target="_blank">KB0018284 - How do I log in to Aire on Linux or Mac OS from off Campus?</a>

For more information on connecting to the University network via the VPN or SSH, please see the following articles:

+ <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0014674" target="_blank">KB0014674 - SSH remote access at the University of Leeds</a>
+ <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0014410" target="_blank">KB0014410 - Connecting to the University VPN</a>


Note that all the above articles require you to log in with your University account to view.


:::{note}
For security reasons, Aire no longer supports SSH key-based authentication for logins. Linux users who previously accessed Aire using SSH keys should update their configuration by removing any existing Aire entries from the `~/.ssh/known_hosts` file to prevent potential connection issues.
:::
