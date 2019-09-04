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

crush_height_of_hlist = function (head, bgroup) 
   for item in node.traverse_id(node.id("vlist"), head) do
   end
   return head
end

-- crush vlist under hlist
crush_height_of_vlist = function (head, group, size)
   for list in node.traverse(head) do
      if list.id == node.id("vlist") or list.id == node.id("hlist") or list.id == node.id("rule")
      then
         local h = list.height
         local d = list.depth
         
         for item in node.traverse(list) do
            local f = node.has_attribute(item, 200)
            
            if f
            then
               if not node.has_attribute(item, 300)
               then
                  -- need to shift the page bottom upword to make a room for footins.
                  -- this code is still wrong, though... 
                  node.set_attribute(item, 300, item.height)
                  item.height = h-item.height
                  item.depth = d-item.depth
               else
                  item.height = 0
                  item.depth = 0
               end
            end
         end
      end
   end
   return head
end

move_footnote_bottom = function (page_head, group, s)
   local yaftnins = node.new("vlist")
   yaftnins.list, new = node.insert_before(yaftnins.list, yaftnins.list, node.copy(tex.box.yaftnins))
   
   recur = function (head, under_hlist, page_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            page_head = recur_vlist(item, under_hlist, page_head)
         elseif item.id == node.id("hlist")
         then
            page_head = recur_hlist(item, page_head)
         end
      end
      return page_head
   end

   recur_hlist = function (hlist, page_head)
      for vlist in node.traverse_id("vlist", hlist) do
         page_head = recur(hlist.head, vlist, page_head)
      end
      return page_head
   end

   recur_vlist = function (head, under_hlist, page_head)
      for vlist in node.traverse(head) do
         local footnotebox = node.has_attribute(vlist, 200)
         
         if footnotebox then
            footnote = node.copy(tex.box[footnotebox])
            page_head = node.remove(page_head, vlist)
            if yaftnins
            then
               yaftnins.list, new = node.insert_after(yaftnins.list, yaftnins.tail, footnote)
            end
         else
            if vlist.head
            then
               page_head = recur(vlist.head, under_hlist, page_head)
            end
         end
      end
      return page_head
   end
   
   page_head = recur(page_head, nil, page_head)
   if yaftnins.list
   then
      tex.box.footins = node.copy(node.vpack(yaftnins.list))
   end

   return page_head
end

function buildpage_info(groupcode)
   lastnode = tex.lists.contrib_head
   if lastnode
      then
      temp = node.tail(lastnode)
      if temp and temp.id == node.id("hlist")
      then
         print("\nMoving page contents at height = "..temp.height.."sp")
      end
   end
end

