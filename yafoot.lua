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

crush_height_of_hlist = function (head, group, size)
   local acc_height = 0
   local acc_depth = 0

   recur = function (head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            local footnotebox = node.has_attribute(item, 200)
            if footnotebox then
               footnote_node = node.copy(tex.box[footnotebox])
               acc_height = acc_height + footnote_node.height
               acc_depth = acc_depth + footnote_node.depth
            end
         end
         item = item.next
      end
   end
   
      for hitem in node.traverse_id(node.id("hlist"), head) do
         if hitem.subtype == 1 or hitem.subtype == 2
         then
            for item in node.traverse_id(node.id("vlist"), hitem) do
               local h = item.height
               local d = item.depth
               local f = node.has_attribute(item, 200)
               if f
               then
                  recur(item)
                  if group == "vbox" or group == "vtop"
                  then
                     item.height = tex.sp("0pt")
                     item.depth = tex.sp("0pt")
                  elseif group == "split_keep" or group == "split_off"
                  then
                     item.height = acc_height - acc_depth
                     item.depth = acc_depth + tex.sp("10pt")
                  else
                     item.height = h
                     item.depth = d
                  end
                  
                  acc_height = 0
                  acc_depth = 0
               end
            item = item.next 
            end
         end
         hitem = hitem.next 
      end
   
   return head
end

move_footnote_bottom = function (page_head, group, s)
   local vbox = node.copy(tex.box.vfillbox)
   local footins = node.new("vlist")
   footins.list, new = node.insert_before(footins.list, footins.list, node.copy(tex.box.footins))
   
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
      page_head = recur(hlist.head, true, page_head)
      return page_head
   end

   recur_vlist = function (vlist, under_hlist, page_head)
      local footnotebox = node.has_attribute(vlist, 200)

      if footnotebox then
         footnote = node.copy(tex.box[footnotebox])
         page_head = node.remove(page_head, vlist)
         if footins
         then
            footins.list, new = node.insert_after(footins.list, footins.list, footnote)
            texio.write_nl("FOOTINS " .. tostring(footins.list))
         end         
      else
         if vlist.head
         then
            page_head = recur(vlist.head, under_hlist, page_head)
         end
      end
      return page_head
   end

   page_head = recur(page_head, false, page_head)
   if footins.list
   then
      tex.box.footins = node.copy(node.vpack(footins.list))
   end
   return page_head
end

