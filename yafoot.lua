push_footnotes_below_lines = function (head, group)
--   texio.write_nl("Found a Footnote!!!" .. tostring(group))
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
         local footnote = node.copy(tex.box[is_footnote])
         head, new = node.insert_after(head, item, footnote)         
         node.set_attribute(new, 200, is_footnote)

         item = item.next
      end
   end
   return head
end



let_footnote_bottom = function (page_head, group, s)
   local vbox = node.copy(tex.box.vfillbox)
   local acc_depth = 0
   page_tail = node.slide(page_head)
   page_head = node.insert_after(page_head, page_tail, vbox)
   
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
         footnote_node = node.copy(tex.box[footnotebox])
         page_head = node.remove(page_head, vlist)
         page_tail = node.slide(page_head)
         
         -- if the vlist is under a hlist, the height should be decreased from the hlist,
         -- in order to prevent the hlist from stretching to the bottom.
         if under_hlist
         then
            acc_depth = acc_depth + footnote_node.depth
         end

         page_head, new = node.insert_after(page_head, page_tail, footnote_node)
      else
         if vlist.head
         then
            page_head = recur(vlist.head, under_hlist, page_head)
         end
      end
      return page_head
   end

   page_head = recur(page_head, false, page_head)

   -- decrease the height of hlist when necessarly.
   for hitem in node.traverse_id(node.id("hlist"), page_head) do
      if hitem.subtype == 1 -- or hitem.subtype == 2
      then
         local skip = tex.splittopskip
         hitem.depth = hitem.depth - acc_depth
         acc_depth = 0
      end
--[[
         local tempbox = node.copy(tex.box.tempbox)
         for glue in node.traverse_id(node.id("hlist"), hitem) do
            if hitem.subtype == 2
            then
               node.remove(hitem, glue) --hitem.depth - acc_depth
            end
         end
--]]
      
   end


   return page_head
end
