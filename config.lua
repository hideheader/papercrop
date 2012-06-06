-----------------------------------------------------------------
-- list of known configurations for reference. You still have to manually
-- edit the user setting below. (search for user settings)
-- please send me e-mail if you know your device's correct configuration.
---------------------------------------------------------------------

kindle2 = {560,735, pad_right=3, pad_bottom=4, mark_corners=true, color_depth=8}  -- color_depth==4 seems to have bugs when resolutions are odd numbers.
kindle3 = kindle2   -- not sure. previous default was {552,736} 
cybook = {600, 800} -- when title bar is hidden
kobo_wireless_old_firmware = {582,740} -- Up to firmware version 1.7.4. Huge waste of screen real estate. 
kobo_wireless= {600,800, output_format=".cbz"} -- Kobo wireless firmware 1.9 started to support CBZ. This format has faster page turning speed and fullscreen!
-- android tablet: the perfect viewer app (modify resolution 600,800 to your device's vertical mode resolution)
android_old={600,800, gamma=1.0, output_format=".cbz", default_split='(outputs a single image per page)', default_preset="presets/two-column papers (portrait).lua" } -- android comic viewer: adjust resolution to match your device
--  output vector graphic PDF files (no rasterization).
vector_PDF={0,0,output_format=".xml", default_split='(outputs a single image per page)', default_preset="presets/two-column papers (portrait).lua" } -- android comic viewer: adjust resolution to match your device

sony_PRS_T1={594-2-2-2-2-2,733-4-3-3-2-5-2+8+8+8+8, landscapeRotate='rotateLeft', mark_corners=true, move_to_folder_linux='/media/READER/Books'}
-- other kindles, sony readers, etc -- Please let me know if you know. I've got many e-mails asking about this.

---------------------------------------------------------------------
-- user settings
---------------------------------------------------------------------

device={600,800} -- {device_width, device_height}
--uncomment if your device is listed below
--device=kindle2
--device=kindle3
--device=kobo_wireless_old_firmware
--device=kobo_wireless
--device=cybook
--device=android
--device=vector_PDF
device=sony_PRS_T1

---------------------------------------------------------------------
-- default options
---------------------------------------------------------------------
function setDefault()

	-- Do not edit below unless you know what you are doing. Edit line 22 instead.
	device.gamma=device.gamma or 0.5
	device.default_split=device.default_split or '(outputs multiple images)'
	default_preset="presets/two-column papers (landscape).lua"
	scroll_overlap_pixels=40
	output_format=".png" -- ".jpg", ".png", ".gif" are supported
	output_to_pdf=true -- output to a pdf or cbz file, instead of multiple image files when possible. (to use cbz search for kobo_wireless)
	color_depth=device.color_depth or 4 -- 2 (4grey) or 4 (16grey) or 8 (256grey) or 24 (color) -- Settings 2 and 4 apply dithering. 
	force_resolution=true
	use_4xsupersampling=false -- better quality output for scanned documents, but slower.
	nr_of_pages_per_pdf_book = 100;
	max_vspace=16 -- pixels

	if os.isUnix() then
		move_to_folder=device.move_to_folder_linux
	end
	--move_to_folder="h:\\ebooks" -- uncomment and edit if you want to automatically move the output file to the ebook device
	landscapeRotate=device.landscapeRotate or "rotateRight"
	device_width=device[1]
	device_height=device[2]
	if use_4xsupersampling then
		device_width=device_width*2
		device_height=device_height*2
	end

	if landscapeRotate=="rotateLeft" then
		landscapeRotate=function (img) img:rotateLeft() end
	else
		landscapeRotate=function (img) img:rotateRight() end
	end
end

setDefault()

devices={['kindle 2']=kindle2, ['kindle 3']=kindle3, ['cybook (no title bar)']=cybook, ['kobo wireless']=kobo_wireless,
['android (width 600)']=android, ['sony PRS-t1']=sony_PRS_T1, ['vector PDF']=vector_PDF}


---------------------------------------------------------------------
-- split books                                                     --
---------------------------------------------------------------------


book_pages = {
	book_part_nr,
	nr_of_pages
};

require('CBZwriter')

function book_pages:clearCache()
	book_pages.cache={}
	book_pages.cache.pages=array:new()
end
function book_pages:init(part_nr,outdir)
	self.book_part_nr = part_nr;
	self.nr_of_pages = 0;
	self.outdir=outdir
	if device and device.output_format==".cbz" then
		self.filename=outdir.."_"..tostring(part_nr)..".cbz"
		self.outpdf=CBZwriter:new(self.filename)
	elseif device and device.output_format==".xml" then
		self.filename=outdir.."_"..tostring(part_nr)..".xml"
		self.outpdf=XMLwriter:new(self.filename,self, outdir)
	else
		self.filename=outdir.."_"..tostring(part_nr)..".pdf"
		self.outpdf=PDFWriter()
	end
	print('book_pages: init '..self.filename)
	self.outpdf:init()
end

function book_pages:init_for_next_part()
	self:init(self.book_part_nr + 1, self.outdir);
end

function book_pages:add_page (image, outdir)
	self.nr_of_pages = self.nr_of_pages + 1;
	if color_depth>8 then
		self.outpdf:addPageColor(image)
	else
		self.outpdf:addPage(image, color_depth)
	end
	collectgarbage();
end
function book_pages:add_current_page()
	assert (self.nr_of_pages==nil)
end

function book_pages:writeToFile(outdir)
	if self.nr_of_pages > 0 then
		local fn=self.filename
		self.outpdf:save(fn);

		if move_to_folder then
			if os.isUnix() then
				local cmd='mv "'..fn..'" "'..move_to_folder..'/"'
				print(cmd)
				os.execute(cmd)
			else
				local fn2=string.gsub(fn,"/", "\\")
				local cmd='move /Y "'..fn2..'" '..move_to_folder
				print(cmd)
				os.execute(cmd)
			end
		else
			if string.sub(fn,-3)=="xml" then
				fn=string.sub(fn,1,-4).."pdf"
			end
			local fn2=Fltk.ChooseFile('save as '.. os.filename(fn)..'?', fn, '*.'..string.sub(fn,-3), true)
			print(fn,fn2)
			if fn and fn~=fn2 and fn2 then
				if os.isUnix() then
					local cmd='cp "'..fn..'" "'..fn2..'"'
					print(cmd)
					os.execute(cmd)
				else
					local fn3=string.gsub(fn,"/", "\\")
					local fn4=string.gsub(fn2,"/", "\\")
					local cmd='move /Y "'..fn3..'" "'..fn4..'"'
					print(cmd)
					os.execute(cmd)
				end
				win:setStatus('saved as '..fn2)
			else
				win:setStatus('Saved as '..fn)
			end
		end

		collectgarbage();
	end;
end
---------------------------------------------------------------------


--outpdf=PDFWriter()

function initializeOutput(outdir)
	if output_to_pdf then
		--vv--outpdf:init();
		book_pages:init(1,outdir);
		--^^--
	else
		win:deleteAllFiles()
	end
end

function outputImage(image, outdir, pageNo, rectNo)

	local device_width=device_width
	local device_height=device_height
	do
		if device.output_format~=".xml" then
			local image=image
			if use_4xsupersampling then
				device_width=device_width/2
				device_height=device_height/2
				local image_4x=image
				image=CImage()
				image:downsample4(image_4x)
			end
			if force_resolution then
				local pad_right=device.pad_right or 0
				local pad_bottom=device.pad_bottom  or 0
				if image:GetWidth()<device_width+pad_right or image:GetHeight()<device_height+pad_bottom then
					local img=CImage()
					img:CopyFrom(image)
					local new_width=math.max(image:GetWidth(), device_width + pad_right)
					local new_height=math.max(image:GetHeight(), device_height + pad_bottom)
					image:create(new_width, new_height)
					image:drawBox(TRect(0,0,image:GetWidth(), image:GetHeight()), 255,255,255)
					local y=math.max(device_height-img:GetHeight(),0)
					local x=math.max(device_width-img:GetWidth(),0)
					image:blit(img, TRect(0,0,img:GetWidth(), img:GetHeight()), x,y)

					if device.mark_corners then
						image:drawBox(TRect(0,0,1,1),0,0,0)
						image:drawBox(TRect(device_width-1,0,device_width,1),0,0,0)
						image:drawBox(TRect(0,device_height-1,1,device_height),0,0,0)
						image:drawBox(TRect(device_width-1,device_height-1,device_width,device_height),0,0,0)
					end
				end
			end
		end

		if output_to_pdf and book_pages.nr_of_pages~=nil then ----if output_to_pdf and outpdf:isValid() then
			if (book_pages.nr_of_pages < nr_of_pages_per_pdf_book) then
				book_pages:add_page(image, outdir);
			else
				book_pages:writeToFile(outdir);
				book_pages:init_for_next_part();
				book_pages:add_page(image, outdir);
			end

		else
			if device.output_format==".xml" then
				book_pages:add_current_page()
			else
				if output_to_pdf then
					print('Warning! output to a jpg file instead of a pdf file. (Process current page?)')
				end
				--		image:Save(string.format("%s/%05d_%03d%s",outdir,pageNo,rectNo,output_format))
				if color_depth<=8 then
					if output_format==".jpg" then
						image:save(string.format("%s/%05d_%03d%s",outdir,pageNo,rectNo,output_format),8)
					else -- png support all bit depths
						image:save(string.format("%s/%05d_%03d%s",outdir,pageNo,rectNo,output_format), color_depth)
					end
				else
					image:Save(string.format("%s/%05d_%03d%s",outdir,pageNo,rectNo,output_format))
				end
			end
		end
	end
end

function finalizeOutput(outdir)
	--vv--if output_to_pdf and outpdf:isValid() then
	--vv--  outpdf:save(outdir.."_output.pdf")
	if output_to_pdf then
		book_pages:writeToFile(outdir);
		book_pages:init(0,outdir);
	end
	--^^--
end

function postprocessImage(image)
	-- sharpen(amount in [1, 2.5], iterations), see ilu manual for more details.
	--image:sharpen(1.5, 1)
	--image:contrast(1.5)
	--    image:gamma(0.5) -- uncomment if you want thicker fonts.
	if color_depth<8 then
		image:gamma(device.gamma) -- e-ink devices tends to have low contrast.
	end

	if color_depth==2 then
		image:dither(4)
	elseif color_depth==4 then
		image:dither(16)
	end


end

function processPageSubRoutine(imageM, pageNo, width, numRects)

	if device.output_format==".xml" then
		if book_pages.cache==nil then
			book_pages:clearCache()
		end
		book_pages.cache.pages:pushBackIfNotExist(pageNo)
		book_pages.cache[pageNo]={}
		for rectNo=0, numRects-1 do
			win:setStatus("processing"..pageNo.."_"..rectNo)
			local rect=SelectionRectangle()
			win:getRectSize(pageNo, rectNo, rect)
			--print(rect:left(), rect:top(), rect:right(), rect:bottom())
			book_pages.cache[pageNo][rectNo+1]=rect
		end
		return 
	end

	for rectNo=0, numRects-1 do
		win:setStatus("processing"..pageNo.."_"..rectNo)
		local image=CImage()
		win:getRectImage_width(pageNo, rectNo, width, image)

		if image:GetWidth()~=width then
			-- rectify.
			local imageOld=image
			image=CImage()
			image:create(width, imageOld:GetHeight())
			image:drawBox(TRect(0,0, image:GetWidth(), image:GetHeight()), 255,255,255)
			image:blit(imageOld, TRect(0,0,math.min(imageOld:GetWidth(), width),imageOld:GetHeight()),0,0)	 
		end

		--print(width, image:GetWidth())

		if imageM:GetHeight()==0 then
			imageM:CopyFrom(image)
		else
			imageM:concatVertical(imageM, image)

		end
	end
	trimVertSpaces(imageM, 2, max_vspace, 255)
end

function splitImage_old(imageM, height, outdir, pageNo, rotateRight)

	if imageM:GetHeight()>height then
		-- split into multiple subpages 
		numSubPage=math.ceil((imageM:GetHeight()-scroll_overlap_pixels)/height)
		win:setStatus("num"..numSubPage)
		local imageS=CImage()
		startPos=vectorn()
		startPos:linspace(0, imageM:GetHeight()-height, numSubPage)
		for subPage=0, numSubPage-1 do
			start=math.floor(startPos:value(subPage))
			imageS:crop(imageM, 0, start, imageM:GetWidth(), start+height)
			if rotateRight then landscapeRotate(imageS) end
			outputImage(imageS,outdir,pageNo,subPage)
			win:setStatus("saving "..pageNo.."_"..subPage)
		end
	else
		local imageS=CImage()
		imageS:crop(imageM, 0, 0, imageM:GetWidth(), imageM:GetHeight())
		if rotateRight then landscapeRotate(imageS) end
		outputImage(imageS,outdir,pageNo,0)
	end
end

function splitImage(imageM, height, outdir, pageNo, rotateRight)
	-- split into multiple subpages 
	local imageS=CImage()
	local subPage=0

	while true 
		do
			curY=math.floor(subPage*(height-scroll_overlap_pixels))
			--      print(curY, height)
			if curY+height <= imageM:GetHeight() then
				imageS:crop(imageM, 0, curY, imageM:GetWidth(), curY+height)
				if rotateRight then landscapeRotate(imageS) end
				outputImage(imageS,outdir,pageNo,subPage)
				win:setStatus("saving "..pageNo.."_"..subPage)
			else
				imageS:crop(imageM, 0, curY, imageM:GetWidth(), imageM:GetHeight())
				if rotateRight then landscapeRotate(imageS) end
				outputImage(imageS,outdir,pageNo,subPage)
				win:setStatus("saving "..pageNo.."_"..subPage)
				break
			end
			subPage=subPage+1
		end
	end

	function splitImagePart(imageM, height, outdir, pageNo, rotateRight)
		-- split into multiple subpages 
		local imageS=CImage()
		local subPage=0

		while true 
			do
				curY=math.floor(subPage*(height-scroll_overlap_pixels))
				--      print(curY, height)
				if curY+height <= imageM:GetHeight() then
					imageS:crop(imageM, 0, curY, imageM:GetWidth(), curY+height)
					if rotateRight then landscapeRotate(imageS) end
					postprocessImage(imageS)
					outputImage(imageS,outdir,pageNo,subPage)
					win:setStatus("saving "..pageNo.."_"..subPage)
				else
					imageM:crop(imageM, 0, curY, imageM:GetWidth(), imageM:GetHeight())
					break
				end
				subPage=subPage+1
			end
		end

