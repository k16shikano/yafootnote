push_footnotes_below_lines = function (head)
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
--         texio.write_nl("Found a Footnote!!!" .. is_footnote)
         while item do
            local footnote = node.copy(tex.box[is_footnote])
            head, new = node.insert_before(head,item,footnote)
            node.set_attribute(new,200,is_footnote)
            item = item.next
         end
         head = node.remove(head, item)
      end
   end
   return head
end



recur = function (head, page_head, page_tail)
   for item in node.traverse(head) do
      if item.id == node.id("vlist")
      then
         recur_vlist(item, page_head, page_tail)
      elseif item.id == node.id("hlist")
      then
         recur_hlist(item, page_head, page_tail)
      end
   end
   return true
end

recur_hlist = function (hlist, page_head, page_tail)
--   texio.write_nl("Found a HLIST!!!")

   if hlist.head
   then
--[[      
      if hlist.head.id == node.id("glyph")
      then 
         texio.write_nl("Found a GLYPH!!!" .. hlist.head.char)
      end
--]]
      recur(hlist.head, page_head, page_tail)
   end
   return true
end

recur_vlist = function (vlist, page_head, page_tail)
--   texio.write_nl("Found a VLIST!!!")
   local footnotebox = node.has_attribute(vlist, 200)
   if footnotebox
   then
      node.remove(page_head, vlist)
      node.insert_before(page_head, page_tail, tex.box[footnotebox])
   else
      if vlist.head
      then
         recur(vlist.head, page_head, page_tail)
      end
   end
   return true
end


let_footnote_bottom = function (head)
   local vbox = node.copy(tex.box.vfillbox)
   local tail = head.tail
   node.insert_after(head, tail, vbox)

   recur (head, head, tail)
   return true
end
