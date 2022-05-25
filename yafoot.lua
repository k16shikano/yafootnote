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

   local n_head = node.copy_list(page_head)
   recur = function (n)
      for list in node.traverse(n) do
         local footnotebox = node.has_attribute(list, 200)
         if footnotebox
         then
            footnote = node.copy(tex.box[footnotebox])
            n_head = node.remove(n_head, list)
            if yaftnins
            then
               yaftnins.list, new = node.insert_after(
                  yaftnins.list, yaftnins.tail, footnote)
            end
         elseif list.head
         then
            n_head = recur(list.head)
         end
      end
      return n_head
   end
      
   page_head = recur(n_head)

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
         for _,l in ipairs(pages_ftn_ht) do
            if l[1] == pagenumber
            then
               tex.setdimen("global", "my@tcb@ftn@height", l[2])
            end
         end
      end
   elseif groupcode == "vmode_par" or groupcode == "hmode_par"
   then
      ftn_ht = get_ftnheight(tex.lists.contrib_head)
      if ftn_ht > 0
      then
         local new_ftn_ht = ftn_ht

         file = io.open(tex.jobname..".fht", "r")
         io.input(file)
         curr_page_ftn_arr = {}
         for line in file:lines() do
            local curr_line_arr = {}
            for i in string.gmatch(line, "%S+") do
               table.insert(curr_line_arr, tonumber(i))
            end
            if curr_line_arr[1] == pagenumber 
            then
               new_ftn_ht = new_ftn_ht + curr_line_arr[2]
            else
               table.insert(curr_page_ftn_arr, line)
            end
         end
         io.close(file)
         table.insert(curr_page_ftn_arr, pagenumber.." "..new_ftn_ht)
         local table_string = table.concat(curr_page_ftn_arr, "\n")

         file = io.open(tex.jobname..".fht", "w")
         io.output(file)
         io.write(table_string)
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
      elseif node.has_attribute(list, 200)
      then
--         ftnheight = ftnheight + list.height + list.depth
      elseif list.head
      then
         ftnheight = ftnheight + get_ftnheight (list.head)
      end
   end
   return ftnheight
end

