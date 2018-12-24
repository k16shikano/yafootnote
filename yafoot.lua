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

   recur = function (head, list_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            list_head = recur_vlist(item, list_head)
         elseif item.id == node.id("hlist")
         then
            list_head = recur_hlist(item, list_head)
         end
      end
      return list_head
   end

   recur_hlist = function (hlist, list_head)
      for item in node.traverse_id(node.id("vlist"), hlist) do
         local f = node.has_attribute(item, 200)
         if f
         then
            item.height = 0 
            item.depth = 0
         end
         list_head = recur(hlist.head, list_head)
      end

      return list_head
   end

   recur_vlist = function (vlist, list_head)
      local acc_h = 0
      for item in node.traverse_id(node.id("vlist"), vlist) do
         local f = node.has_attribute(vlist, 200)
         if f
         then
            acc_h = acc_h + item.height + tex.box[f].height
         end
      end
      vlist.height = vlist.height + acc_h
      vlist.depth = vlist.depth + acc_h

      if vlist.head
      then 
         list_head = recur(vlist.head, list_head)
      end
      
      return list_head
   end

   recur(head, head)

   return head
end

move_footnote_bottom = function (page_head, group, s)
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
            footins.list, new = node.insert_after(footins.list, footins.tail, footnote)
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

