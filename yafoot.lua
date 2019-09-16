pagenumber = 0

local file = io.open(tex.jobname..".fht", "r")
io.input(file)
local pages_ftn_ht = {}
local has_pages_ftn_ht = false
for line in file:lines() do
   local line_arr = {}
   for i in string.gmatch(line, "%S+") do
      table.insert(line_arr, tonumber(i))
   end
   table.insert(pages_ftn_ht, line_arr)
   has_pages_ftn_ht = true
end
io.close(file)
local file = io.open(tex.jobname..".fht", "w")
io.close(file)

if pages_ftn_ht[1] and pages_ftn_ht[1][1] == 0
then
   tex.setdimen("global", "my@tcb@ftn@height", pages_ftn_ht[1][2])
end

push_footnotes_below_lines = function (head, group)
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
         local footnote = node.copy(tex.box[is_footnote])
         head, new = node.insert_after(head, item, footnote)
         node.set_attribute(new, 200, is_footnote)
         item = item.next
         new.width = 0
      end
   end
   return head
end

-- crush vlist under hlist
crush_height_of_vlist = function (head, group, size)
   for list in node.traverse(head) do
      if list.id == node.id("hlist")
      then
      for item in node.traverse(list) do
         local f = node.has_attribute(item, 200)
         if f
         then
            if not node.has_attribute(item, 300)
            then
               node.set_attribute(item, 300, item.height+item.depth)
               item.height = 0
               item.depth = 0
            else
            end
         end
      end
      end
   end
   
   return head
end

move_footnote_bottom = function (page_head, group, s)
   local yaftnins = node.new("vlist")
   void = node.new("vlist")
   yaftnins.list, new = node.insert_before(yaftnins.list, yaftnins.list, node.copy(tex.box.footins))
   
   recur = function (head, isftn, page_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            page_head = recur_vlist(item, isftn, page_head)
         elseif item.id == node.id("hlist")
         then
            page_head = recur_hlist(item, isftn, page_head)
         end
      end
      return page_head
   end

   recur_hlist = function (hlist, isftn, page_head)
      for item in node.traverse(hlist.head) do
         if item.id == node.id("hlist") or item.id == node.id("vlist")
         then
            page_head = recur(item, isftn, page_head)
         end
      end
      return page_head
   end

   recur_vlist = function (head, isftn, page_head)
      for vlist in node.traverse_id(node.id("vlist"), head) do
         local footnotebox = node.has_attribute(vlist, 200)
         
         if footnotebox then
            footnote = node.copy(tex.box[footnotebox])
            page_head = node.remove(page_head, vlist)
            if yaftnins
            then
               yaftnins.list, new = node.insert_after(yaftnins.list, yaftnins.tail, footnote)
            end
            page_head = recur(vlist.head, true, page_head)
         else
            if vlist.head
            then
               page_head = recur(vlist.head, isftn, page_head)
            end
         end
      end
      return page_head
   end
   
   recur(page_head, false, page_head)

   local split_top
   if yaftnins.list
   then
      tex.box.footins = node.copy(node.vpack(yaftnins.list))
   end
   
   return page_head
end

-- called after the page was built (or tried to build)
function page_ftn_height(groupcode)
   if groupcode == "after_output"
   then
      pagenumber = pagenumber+1
      if has_pages_ftn_ht
      then
         for i,l in ipairs(pages_ftn_ht) do
            if tonumber(l[1]) == pagenumber
            then
               tex.setdimen("global", "my@tcb@ftn@height", tonumber(l[2]))
            end
         end
      end
   elseif groupcode == "vmode_par" or groupcode == "hmode_par"
   then
      ftn_ht = get_ftnheight(tex.lists.contrib_head)
      if ftn_ht > 0
      then
         tex.setdimen("global", "my@tcb@ftn@height", ftn_ht + tex.getdimen("footskip"))
         file = io.open(tex.jobname..".fht", "a")
         io.output(file)
         io.write(pagenumber.." "..ftn_ht + tex.getdimen("footskip").."\n")
         io.close(file)
      end
   end
end

get_ftnheight = function (n)
   local ftnheight = 0
   for list in node.traverse(n) do
      if node.has_attribute(list, 300)
      then
         ftnheight = ftnheight + node.get_attribute(list, 300)
         node.unset_attribute(list, 300)
      elseif list.head
      then
         ftnheight = ftnheight + get_ftnheight (list.head)
      end
   end
   return ftnheight
end

