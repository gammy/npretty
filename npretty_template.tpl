[NPRETTY_BLOCK_THUMB]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>[NPRETTY_TITLE_EXIST][NPRETTY_TITLE][/NPRETTY_TITLE_EXIST][NPRETTY_TITLE_NOEXIST]Gallery[/NPRETTY_TITLE_NOEXIST]</title>
    <style type="text/css">
	body {
		background-color: #000
		font-family: tahoma, arial, verdana;
	}
	a {
		color: #000;
		text-decoration: none;
	}
	a:visited {
		color: #000;
	}
	a:active,a:hover {
		color: #c0c0c0
	}
	table {
		border: 1px #000 solid;
		border-collapse: collapse;
		color: #000;
	}
	td {
		font-family: tahoma, arial, verdana;
		font-size: 12px;
		border: 1px #000 solid;
		text-align: center;
		vertical-align: bottom;
	}
	img {
		border: 0px;
	}
	.pagetable {
		width: 600px;
	}
	.pagecells {
		height: 15px;
	}
	.arrowtable {
		width: 100%;
		height: 15px;
		border: 0px;
		padding: 0px;
		margin: 0px;
		font-weight: bold;
	}
	.thumbtable {
		background-color: #000;
		border: 0px;
		margin: 0px;
		padding: 0px;
	}
	.thumbcell {
	  	color: #ffffff;
		width: 133px;
		height: 100px;
		vertical-align: middle;
		padding: 0px;
		border: 1px #000 solid;
	}
	.half {
		width: 50%;
		height: 17px;
		border: 1px #000 solid;
	}
	.container {
		width: 598px;
		padding: 28px 0 28px 0;;
		border: 1px #000 solid;
	}
	h1 {
		font-size: 15px;
		display: inline;
	}
</style>
</head>
<body>
	<center>
    <table class="pagetable">[NPRETTY_TITLE_EXIST]
    	<tr>
    		<td colspan="3">
    			<h1>[NPRETTY_TITLE]</h1>
    		</td>
    	</tr>[/NPRETTY_TITLE_EXIST][NPRETTY_TITLE_NOEXIST] [/NPRETTY_TITLE_NOEXIST]
    	<tr>
    		<td class="half">
    			<a href="../" title="Back">Home</a>
    		</td>
    		<td class="half">[NPRETTY_LIST]<a href="[NPRETTY_LIST_PAGE]" class="pagelist">[NPRETTY_LIST_NUM]</a>&nbsp;[/NPRETTY_LIST][NPRETTY_LIST_IFSEL]<b>[NPRETTY_LIST_NUM]&nbsp;</b>[/NPRETTY_LIST_IFSEL]</td>
    	</tr>
    	<tr>
    		<td class="half" style="border-right: 0px; font-weight: bold;">[NPRETTY_PREV_EXIST]<a href="[NPRETTY_PREV_PAGE]" title="Previous page ([NPRETTY_PREV_PAGE_NUM])" class="pagelist">Previous</a>[/NPRETTY_PREV_EXIST][NPRETTY_PREV_NOEXIST] [/NPRETTY_PREV_NOEXIST]</td>
    		<td class="half"style="border-left: 0px; font-weight: bold;">[NPRETTY_NEXT_EXIST]<a href="[NPRETTY_NEXT_PAGE]" title="Next page ([NPRETTY_NEXT_PAGE_NUM])" class="pagelist">Next</a>[/NPRETTY_NEXT_EXIST][NPRETTY_NEXT_NOEXIST] [/NPRETTY_NEXT_NOEXIST]</td>
    	</tr>
	</table>
      <br><br>
      <div class="container">
		  <table class="thumbtable">
			<tr>
			  [NPRETTY_BODY]
			</tr>
		  </table>
      </div>
    </center>
  </body>
</html>
[/NPRETTY_BLOCK_THUMB]

[NPRETTY_BLOCK_BODY]
        <td class="thumbcell"><a href="[NPRETTY_PREVIEW_PAGE]" title="[NPRETTY_COMMENT]"><img src="[NPRETTY_THUMB]" alt="[NPRETTY_COMMENT] ([NPRETTY_SIZE])"></a></td>
        [NPRETTY_DEL_4]
        </tr><tr>
        [/NPRETTY_DEL]
	[NPRETTY_PAD_DEL]
	<td class="thumbcell" style="background-color: #fff; border: 0px;"></td>
	[/NPRETTY_PAD_DEL]
[/NPRETTY_BLOCK_BODY]

[NPRETTY_BLOCK_PREVIEW]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>[NPRETTY_COMMENT]</title>
        <style type="text/css">
			body {
				font-family: tahoma, arial, verdana;
				font-size: 10px;
			}
			a {
				color: #000;
				text-decoration: none;
			}
			a:visited {
				color: #000;
			}
			a:active,a:hover {
				color: #c0c0c0
			}
			table {
				border: 1px #000 solid;
				border-collapse:collapse;
				color:#000;
			}
			td {
				font-family: tahoma, arial, verdana;
				vertical-align: bottom;
			}
			img {
				border: 0px #000 solid;
			}
			.image {
				border: 1px #000 solid;
				padding: 0px;
			}
			.pagetable {
				width: 600px;
				height: 15px;
				border: 1px #000 solid;
				font-size: 12px;
				text-align: center;
			}
			.half {
				width: 50%;
				height: 17px;
				border: 1px #000 solid;
			}
			.arrowtable {
				border: 1px #000 solid;
				width: 100%;
				height: 15px;
				border: 0px;
				padding: 0px;
				margin: 0px;
				font-weight: bold;
				font-size: 12px;
				text-align: center;
			}
			.pagelist {
				text-decoration: none;
			}
			.comment {
				font-size: 11px;
				font-weight: bold;
				text-align: center;
				vertical-align: middle;
				border: 1px #000 solid;
				height: 25px;
				margin: 0px;
				padding: 0px;
			}
			#info {
				padding: 5px;
				position: absolute;
				background-color: #fff;
				border-right: 1px #000 solid;
				border-bottom: 1px #000 solid;
				display: none;
			}
			.infotable {
				border: 0px;
				width: 180px;
				text-align: left;
				font-size: 10px;
			}
			.imagetable {
				padding: 0px;
				border: 0px;
			}
			h1 {
				font-size: 15px;
				display: inline;
			}
		</style>
  </head>
  <body id="body">
  	<center>
			<table class="pagetable">[NPRETTY_TITLE_EXIST]
				<tr>
					<td colspan="3">
						<h1>[NPRETTY_TITLE]</h1>
					</td>
				</tr>[/NPRETTY_TITLE_EXIST][NPRETTY_TITLE_NOEXIST] [/NPRETTY_TITLE_NOEXIST]
					<tr>
						<td class="half">
							<a href="[NPRETTY_PAGE]" title="Back to thumbnails">Back to thumbnails</a>
						</td>
						<td class="pagetable">
							[NPRETTY_PREV_LIST]<a href="[NPRETTY_PREV_LIST_PAGE]" class="pagelist">[NPRETTY_PREV_LIST_NUM]</a>&nbsp;[/NPRETTY_PREV_LIST]
							[NPRETTY_PREV_LIST_IFSEL]<b>[NPRETTY_PREV_LIST_NUM]</b>&nbsp;[/NPRETTY_PREV_LIST_IFSEL]
						</td>
					</tr>
					<tr>
						<td class="half" style="border-right: 0px; font-weight: bold;">
							[NPRETTY_PREV_IMG_EXIST]<a href="[NPRETTY_PREV_IMG]" title="Previous ([NPRETTY_PREV_IMG_NAME])" accesskey="z">Previous</a>[/NPRETTY_PREV_IMG_EXIST]
							[NPRETTY_PREV_IMG_NOEXIST] [/NPRETTY_PREV_IMG_NOEXIST]
						</td>
						<td class="half" style="border-left: 0px; font-weight: bold;">
							[NPRETTY_NEXT_IMG_EXIST]<a href="[NPRETTY_NEXT_IMG]" title="Next ([NPRETTY_NEXT_IMG_NAME])" accesskey="x">Next</a>[/NPRETTY_NEXT_IMG_EXIST]
							[NPRETTY_NEXT_IMG_NOEXIST] [/NPRETTY_NEXT_IMG_NOEXIST]
						</td>
					</tr>
			</table>
		<br><br>

			<table class="imagetable">
				<tr>
					<td class="comment">
						[NPRETTY_FILENAME]
					</td>
				</tr>
				<tr>
					<td class="image">
						<div id="info" onmouseover="document.getElementById('info').style.display='inline'" onmouseout="document.getElementById('info').style.display='none'">
							<table class="infotable">
								<tr>
									<td>
										Camera model:
									</td>
									<td>
										[NPRETTY_EXIF_Model]
									</td>
								</tr>
								<tr>
									<td>
										Lense:
									</td>
									<td>
										[NPRETTY_EXIF_Lens]
									</td>
								</tr>
								<tr>
									<td>
										Focal Lenght:
									</td>
									<td>
										[NPRETTY_EXIF_FocalLength]
									</td>
								</tr>
								<tr>
									<td>
										Focal Lenght (35 eq):
									</td>
									<td>
										[NPRETTY_EXIF_FocalLengthIn35mmFormat]
									</td>
								</tr>
								<tr>
									<td>
										Focus distance:
									</td>
									<td>
										[NPRETTY_EXIF_FocusDistance]
									</td>
								</tr>
								<tr>
									<td>
										Shutter time:
									</td>
									<td>
										[NPRETTY_EXIF_ShutterSpeed]
									</td>
								</tr>
								<tr>
									<td>
										Aperture:
									</td>
									<td>
										[NPRETTY_EXIF_Aperture]
									</td>
								</tr>
								<tr>
									<td>
										ISO:
									</td>
									<td>
										[NPRETTY_EXIF_ISO]
									</td>
								</tr>
								<tr>
									<td>
										Resolution:
									</td>
									<td>
										[NPRETTY_EXIF_ImageSize]
									</td>
								</tr>
								<tr>
									<td>
										Size:
									</td>
									<td>
										[NPRETTY_SIZE]
									</td>
								</tr>
								<tr>
									<td style="vertical-align: top; padding-top: 10px;">
										Background colour
									</td>
									<td style="padding-top: 10px; text-decoration: underline;">
										<a href="#" onclick="document.getElementById('body').style.backgroundColor='#ffffff'">White</a><br>
										<a href="#" onclick="document.getElementById('body').style.backgroundColor='#aaaaaa'">Gray</a><br>
										<a href="#" onclick="document.getElementById('body').style.backgroundColor='#000000'">Black</a><br>
							</table>
						</div>
						<a href="[NPRETTY_IMAGE]" title="[NPRETTY_COMMENT]" onmouseover="document.getElementById('info').style.display='inline'" onmouseout="document.getElementById('info').style.display='none'"><img src="[NPRETTY_PREVIEW]" alt="[NPRETTY_FILENAME]"></a></td>
				</tr>
		[NPRETTY_COMMENT_EXIST]
				<tr>
					<td class="comment">
						[NPRETTY_COMMENT]
					</td>
				</tr>
		[/NPRETTY_COMMENT_EXIST]
			</table>
   </center>
  </body>
</html>
[/NPRETTY_BLOCK_PREVIEW]
