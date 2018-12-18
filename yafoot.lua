push_footnotes_below_lines = function (head)
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
--         texio.write_nl("Found a Footnote!!!" .. is_footnote)
         local footnote = node.copy(tex.box[is_footnote])
         head, new = node.insert_before(head,item,footnote)
         node.set_attribute(new,200,is_footnote)
         item = item.next
      end
   end
   return head
end


let_footnote_bottom = function (page_head, _, s)
   local vbox = node.copy(tex.box.vfillbox)
   page_tail = node.slide(page_head)
   page_head = node.insert_after(page_head, page_tail, vbox)
   
   recur = function (head, page_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            page_head = recur_vlist(item, page_head)
         elseif item.id == node.id("hlist")
         then
            page_head = recur_hlist(item, page_head)
         end
      end
      return page_head
   end

   recur_hlist = function (hlist, page_head)
      if hlist.head
      then
         page_head = recur(hlist.head, page_head)
      end
      return page_head
   end

   recur_vlist = function (vlist, page_head)
      local footnotebox = node.has_attribute(vlist, 200)
            
      if footnotebox
      then
         --[[
         if tex.box[footnotebox]
         then
            texio.write_nl("Found a Footnote!!!" .. tostring(footnotebox))
         end
         --]]
         
         page_head = node.remove(page_head, vlist)
         page_tail = node.slide(page_head)

         page_head = node.insert_before(page_head, page_tail, tex.box[footnotebox])
      else
         if vlist.head
         then
            page_head = recur(vlist.head, page_head)
         end
      end
      return page_head
   end

   page_head = recur(page_head, page_head)
   return page_head
end
