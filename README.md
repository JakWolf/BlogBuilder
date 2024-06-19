# Overview
When generating the blog page, all files get read from the `in` folder and all generated files get copied to the `out` folder. 

There are 3 folder inside the `in` folder you have to know about: `blog_posts`, `templates`, `root`, `resources`.

Every file in the `root` and `blog_posts` folder gets read and rendred out with 
the head, header and footer applied. Those template files get read from the template directory. 
In addition you can wrap blog posts with something like a div in
in `blog_start.html` and `blog_end.html`.

The `resources` folder and the `style.css` just get copied in the root of the `out` folder.

# Vars
You can define variables in the var.txt folder.
The file gets parsed line by line. When using a war in any file in the `root` `blog_posts` or `template` folder 
the string on the left site of `=` gets replaced with the string on 
the right side.
You can use variables everywhere, also in template files.

In the blog posts files, on top of every file, you have to write a comment with two variables:
```
<!--
%%BLOG_POST_NAME=My blog title
%%BLOG_POST_DATE=11/06/2024
-->
```
The format for the date is DD/MM/YYYY. These variables get used for genrating links. You can use them inside
the `blog_posts` file and also inside the `blog_star.html` and `blog_end.html` template files.

Two variables get created automatically: `%%BLOG_POST_LIST` and `%%BLOG_POSTS_ALL`.

`%%BLOG_LIST` is a html list with all blog post links. They get listed in the order of the date with the
newest on top.
`%%ALL_BLOGS_POSTS` is a string with all blog posts concatenate if you just wan't to list them on one page.

Template structure: 


<!DOCTYPE html>
<html>

*HEAD <- head.html*
```
<head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="/style.css"/>

	<style>	</style>

	<title></title>
</head>
```

<body>

*HEADER <- header.html*
```
<header> <- header.html
	<nav>
		<a href="/">Home</a>
		<a href="/all_blog_posts.html">Blog</a>
	</nav>
</header>

<hr>
```
<main>

*INPUT_FILE*
```
<div>
    <h1>This is my blog.</h1>

    <p>Here are some articles generated by AI:<p/>
<p><a href=/blogs/Capitalism.html>Does Capitalism lead to more inequality?</a> <em>10/06/2024</em></p>
<p><a href=/blogs/Browser.html>Why does the browser suck so much?</a> <em>8/06/2024</em></p>

</div>
```
</main>

*FOOTER <- footer.html*
```
<footer>
	<hr>
	Some Guy &copy; &mdash;<a href="mailto:someguy@gmail.com">someguy@gmail.com</a>
</footer>
```

</body>
</htlml>